/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Popup for selecting the segment model (variant) for the current Track

Copyright (C) 2022 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import io.zynthbox.components 1.0 as Zynthbox
import Zynthian 1.0 as Zynthian

Zynthian.Popup {
    id: component
    parent: QQC2.Overlay.overlay
    y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
    x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
    closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
    property var cuiaCallback: function(cuia) {
        var result = component.opened;
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
                component.close();
                result = true;
                break;
            case "SWITCH_SELECT_SHORT":
                component.close();
                result = true;
                break;
            case "NAVIGATE_LEFT":
            case "SELECT_UP":
                _private.goPrevious();
                result = true;
                break;

            case "NAVIGATE_RIGHT":
            case "SELECT_DOWN":
                _private.goNext();
                result = true;
                break;
        }
        return result;
    }

    ColumnLayout {
        Kirigami.Heading {
            Layout.fillWidth: true
            text: "Song Variants"
            QtObject {
                id: _private
                function goPrevious() {
                    if (zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModelIndex > 0) {
                        zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModelIndex -= 1;
                    }
                }
                function goNext() {
                    if (zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModelIndex < zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModelsCount - 1) {
                        zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModelIndex += 1;
                    }
                }
            }
            Zynthian.DialogQuestion {
                id: modelRemover
                function removeVariant(variantIndex) {
                    modelRemover.variantIndex = variantIndex;
                    modelRemover.open();
                }
                property int variantIndex: -1
                onAccepted: {
                    zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.removeSegmentsModel(modelRemover.variantIndex);
                }
                title: qsTr("Remove Variant?")
                text: qsTr("Do you wish to remove Variant %1?\n\nThis cannot be undone.").arg(modelRemover.variantIndex + 1)
            }
        }
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 30
            Layout.preferredHeight: Kirigami.Units.gridUnit * 20
            clip: true
            model: component.opened ? zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModelsCount : 0
            delegate: Zynthian.Card {
                id: variantDelegate
                width: ListView.view.width
                height: ListView.view.height / 7.1
                highlighted: zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModelIndex === model.index
                property QtObject segmentsModel: zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.getSegmentsModel(model.index)
                property int barLength: segmentsModel.totalBeatDuration / 4
                property int beatLength: segmentsModel.totalBeatDuration - (barLength * 4)
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModelIndex = model.index;
                        component.close();
                    }
                }
                RowLayout {
                    anchors{
                        fill: parent
                        margins: 5
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: Text.AlignVCenter
                        textFormat: Text.StyledText
                        text: "Variant %1<br><font size=\"2\">%2 bars and %3 beats in %4 segments</font>".arg(model.index).arg(variantDelegate.barLength).arg(variantDelegate.beatLength).arg(variantDelegate.segmentsModel.count)
                    }
                    QQC2.Button {
                        Layout.fillHeight: true
                        text: qsTr("Clone As New")
                        onClicked: {
                            var newSegmentsModelIndex = zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.cloneAsNew(model.index);
                            zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModelIndex = newSegmentsModelIndex;
                            component.close();
                        }
                    }
                    QQC2.Button {
                        Layout.fillHeight: true
                        text: qsTr("Remove")
                        onClicked: {
                            modelRemover.removeVariant(model.index);
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
            QQC2.Button {
                text: qsTr("New Blank Variant")
                onClicked: {
                    var newSegmentsModelIndex = zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.newSegmentsModel();
                    zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModelIndex = newSegmentsModelIndex;
                    component.close();
                }
            }
            QQC2.Button {
                text: qsTr("Close")
                onClicked: {
                    component.close();
                }
            }
        }
    }
}
