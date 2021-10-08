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

import org.kde.plasma.core 2.0 as PlasmaCore

Zynthian.ScreenPage {
    id: root
    title: zynthian.control.selector_path_element

    backAction: null
    contextualActions: [
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            text: qsTr("Power")
            Kirigami.Action {
                text: qsTr("Restart UI")
                onTriggered: zynthian.main.restart_gui()
            }
            Kirigami.Action {
                text: qsTr("Reboot")
                onTriggered: zynthian.main.reboot()
            }
            Kirigami.Action {
                text: qsTr("Power Off")
                onTriggered: zynthian.main.power_off()
            }
        }
    ]
    screenId: "session_dashboard"
    Timer {
        interval: 10 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        function pad(d) {
            return (d < 10) ? '0' + d.toString() : d.toString();
        }
        onTriggered: {
            let d = new Date();
            clockLabel.text = d.toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit' });
            let sessionSecs = zynthian.session_dashboard.get_session_time()
            let sessionMins = Math.floor(sessionSecs / 60);
            let sessionHours = Math.floor(sessionMins / 60);
            sessionMins = sessionMins % 60;
            sessionTimeLabel.text = pad(sessionHours) + ":" + pad(sessionMins);
        }
    }
    ColumnLayout {
        anchors {
            fill: parent
            topMargin: -Kirigami.Units.smallSpacing
        }
        spacing: Kirigami.Units.largeSpacing
        RowLayout {
            QQC2.Label {
                Layout.alignment: Qt.AlignCenter
                text: "Session time:"
            }
            Kirigami.Heading {
                id: sessionTimeLabel
                Layout.alignment: Qt.AlignCenter
            }
            Item {
                Layout.fillWidth: true
            }
            Kirigami.Heading {
                id: clockLabel
                Layout.alignment: Qt.AlignCenter
            }
        }

        RowLayout {
            ColumnLayout {
                Kirigami.Heading {
                    level: 2
                    text: zynthian.session_dashboard.name
                    MouseArea {
                        anchors.fill: parent
                        onClicked: zynthian.current_modal_screen_id = "sketch_copier"
                    }
                }
                QQC2.ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    ListView {
                        model: zynthian.session_dashboard.sessionSketchesModel
                        header: QQC2.Control {
                            width: parent.width
                            height: layersView.height / 15
                            contentItem: RowLayout {
                                QQC2.Label {
                                    text: "1. " + zynthian.zynthiloops.song.name
                                }
                            }
                        }
                        delegate: QQC2.Control {
                            width: parent.width
                            height: layersView.height / 15
                            contentItem: RowLayout {
                                QQC2.Label {
                                    text: (model.slot + 2) + ". " + (model.sketch ? model.sketch.name : " - ")
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Kirigami.Heading {
                    level: 2
                    text: qsTr("Tracks")
                    MouseArea {
                        anchors.fill: parent
                        onClicked: zynthian.current_modal_screen_id = "zynthiloops"
                    }
                }
                QQC2.ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    ListView {
                        model: zynthian.zynthiloops.song.tracksModel
                        delegate: QQC2.Control {
                            width: parent.width
                            height: layersView.height / 15
                            contentItem: RowLayout {
                                id: delegate
                                property QtObject track: model.track
                                QQC2.Label {
                                    text: (index+1) + "." + (visibleChildren.length > 1 ? model.display : "")
                                    Repeater { //HACK
                                        model: delegate.track.clipsModel
                                        Item {
                                            width: 10
                                            height: 10
                                            visible: model.clip.path.length > 0
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Kirigami.Heading {
                    level: 2
                    text: qsTr("Patterns")
                }
                QQC2.ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                }
            }

            ColumnLayout {
                Kirigami.Heading {
                    level: 2
                    text: qsTr("Sounds")
                    MouseArea {
                        anchors.fill: parent
                        onClicked: zynthian.current_screen_id = "main_layers_view"
                    }
                }
                QQC2.ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    ListView {
                        id: layersView
                        model: zynthian.fixed_layers.selector_list
                        delegate: QQC2.Control {
                            width: layersView.width
                            background: Item {
                                PlasmaCore.FrameSvgItem {
                                    anchors {
                                        fill: parent
                                        margins: -Kirigami.Units.smallSpacing
                                    }
                                    imagePath: "widgets/viewitem"
                                    prefix: "hover"
                                    visible: zynthian.active_midi_channel === index
                                }
                            }
                            height: layersView.height / 15
                            contentItem: RowLayout {
                                QQC2.Label {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: {
                                        let numPrefix = model.metadata.midi_channel + 1;
                                        if (numPrefix > 5 && numPrefix <= 10) {
                                            numPrefix = "6." + (numPrefix - 5);
                                        }
                                        return numPrefix + ". " + model.display
                                    }
                                }
                                QQC2.Label {
                                    text: {
                                        let text = "";
                                        if (model.metadata.note_high < 60) {
                                            text = "L";
                                        } else if (model.metadata.note_low >= 60) {
                                            text = "H";
                                        }
                                        if (model.metadata.octave_transpose !== 0) {
                                            if (model.metadata.octave_transpose > 0) {
                                                text += "+"
                                            }
                                            text += model.metadata.octave_transpose;
                                        }
                                        return text;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
