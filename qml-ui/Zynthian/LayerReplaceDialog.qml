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
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

Zynthian.Dialog {
    id: component
    property int footerLeftPadding: 0
    property int footerRightPadding: 0
    property int footerBottomPadding: 0
    property var sourceChannels: []
    property var destinationChannels: []
    property string fileToLoad
    property string jsonToLoad
    // If you set this to false, make sure to manually call clear after you are done with the dialog's data
    property bool actuallyReplace: true
    function clear () {
        sourceChannels = [];
        destinationChannels = [];
        fileToLoad = "";
        jsonToLoad = "";
    }
    onAccepted: {
        if (actuallyReplace) {
            if (sourceChannels.length !== destinationChannels.length) {
                return;
            }
            let map = {};
            var i = 0;
            for (i in sourceChannels) {
                map[sourceChannels[i]] = destinationChannels[i];
            }
            for (i in map) {
                print("Mapping midi channel " + i + " to " + map[i]);
            }
            if (fileToLoad != "") {
                zynqtgui.layer.load_layer_from_file(fileToLoad, map);
            } else if (jsonToLoad != "") {
                zynqtgui.layer.load_layer_from_json(jsonToLoad, map);
            }
            clear();
        }
    }
    onRejected: {
        clear();
    }
    header: Kirigami.Heading {
        text: qsTr("Pick Layers To Replace")
    }
    contentItem: ColumnLayout {
        QQC2.Label {
            text: qsTr("The selected sound has %1 layers: select %1 adjacent layers that should be replaced by them.").arg(component.sourceChannels.length)
        }
        GridLayout {
            columns: 2
            rows: 8
            flow: GridLayout.TopToBottom
            Repeater {
                id: channelReplaceRepeater
                model: component.visible ? zynqtgui.fixed_layers.selector_list : []
                delegate: QQC2.RadioButton {
                    id: delegate
                    enabled: channelReplaceRepeater.count - index >= component.sourceChannels.length
                    autoExclusive: true
                    onCheckedChanged: {
                        component.destinationChannels = [];
                        var i = 0;
                        let chan = model.metadata.midi_channel
                        for (i in component.sourceChannels) {
                            component.destinationChannels.push(chan);
                            chan++;
                        }
                        component.destinationChannelsChanged();
                        component.sourceChannelsChanged();
                    }
                    Connections {
                        target: component
                        onFileToLoadChanged: {
                            checked = false
                            checked = index === zynqtgui.fixed_layers.current_index
                        }
                    }
                    indicator.opacity: enabled
                    indicator.x: 0
                    contentItem: RowLayout {
                        Item {
                            Layout.preferredWidth: delegate.indicator.width
                        }
                        QQC2.CheckBox {
                            enabled: false
                            checked: component.destinationChannels.indexOf(model.metadata.midi_channel) !== -1
                        }
                        QQC2.Label {
                            text: {
                                let numPrefix = model.metadata.midi_channel + 1;
                                //if (numPrefix > 5 && numPrefix <= 10) {
                                    //numPrefix = "6." + (numPrefix - 5);
                                //}
                                return numPrefix + " - " + model.display;
                            }
                        }
                    }
                }
            }
        }
    }
    footer: QQC2.Control {
        leftPadding: component.footerLeftPadding
        topPadding: Kirigami.Units.smallSpacing
        rightPadding: component.footerRightPadding
        bottomPadding: component.footerBottomPadding
        contentItem: RowLayout {
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                text: qsTr("Cancel")
                onClicked: component.close()
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                enabled: component.destinationChannels.length === component.sourceChannels.length
                text: qsTr("Load && Replace")
                onClicked: component.accept()
            }
        }
    }
}
