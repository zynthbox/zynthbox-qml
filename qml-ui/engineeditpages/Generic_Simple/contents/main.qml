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
import org.kde.plasma.core 2.0 as PlasmaCore
import "." as Here
import Zynthian 1.0 as Zynthian
import QtGraphicalEffects 1.15

Item {
    id: root

    QQC2.Control {

        anchors.fill: parent
        padding: 20

        background: Item {
            PlasmaCore.FrameSvgItem {
                id: svgBg4
                anchors.fill: parent

                readonly property real leftPadding: fixedMargins.left
                readonly property real rightPadding: fixedMargins.right
                readonly property real topPadding: fixedMargins.top
                readonly property real bottomPadding: fixedMargins.bottom

                imagePath: "widgets/tracks-background"
                colorGroup: PlasmaCore.Theme.ViewColorGroup
            }
        }

        contentItem: Item {
            ColumnLayout {
                anchors.fill: parent
                RowLayout {
                    Layout.fillWidth: true
                    QQC2.Label {

                        text: "Generic"
                        font.capitalization: Font.AllUppercase
                        font.weight: Font.ExtraBold
                        font.family: "Hack"
                        font.pointSize: 20
                        Layout.alignment: Qt.AlignTop
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    QQC2.Label {
                        text: zynqtgui.control.selectedEngineCutoffController ? zynqtgui.control.selectedEngineCutoffController.title : ""
                        Layout.alignment: Qt.AlignTop
                        font.capitalization: Font.AllUppercase
                        font.weight: Font.ExtraBold
                        font.family: "Hack"
                        font.pointSize: 20
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 5

                    // Item {
                    //     Layout.fillWidth: true
                    //     Layout.fillHeight: true
                    //     Layout.margins: 5

                    //     RowLayout {
                    //         anchors.fill: parent
                    //         spacing: 5

                    //         Here.SliderControl {
                    //             objectName: "FilterAttack"
                    //             Layout.fillHeight: true
                    //             Layout.fillWidth: true
                    //             slider.orientation: Qt.Vertical
                    //             highlightColor: "#de20ff"
                    //             controller {
                    //                 category: "Ctrls#7"
                    //                 index: 1
                    //             }
                    //         }

                    //         Here.SliderControl {
                    //             objectName: "FilterRelease"
                    //             Layout.fillWidth: true
                    //             Layout.fillHeight: true
                    //             slider.orientation: Qt.Vertical
                    //             highlightColor: "#de20ff"
                    //             controller {
                    //                 category: "Ctrls#8"
                    //                 index: 0
                    //             }
                    //         }
                    //     }
                    // }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 5

                        ColumnLayout {

                            anchors.fill: parent
                            spacing: 5

                            Here.DialControl {
                                objectName: "Cutoff"
                                // highlightColor: "#ff8113"
                                Layout.alignment: Qt.AlignCenter
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                // controller : zynqtgui.control.selectedEngineCutoffController
                                controller {
                                    ctrl: zynqtgui.control.selectedEngineCutoffController
                                    // category: "Ctrls#1"
                                    // index: 0
                                }
                            }

                            // RowLayout {
                            //     Layout.fillWidth: true
                            //     Layout.preferredHeight: 150
                            //     Layout.maximumHeight: 150

                            //     Here.DialControl {
                            //         objectName: "Resonance"
                            //         Layout.fillHeight: true
                            //         Layout.fillWidth: true
                            //         implicitWidth: height
                            //         // highlightColor: "#ff8113"
                            //         controller {
                            //             category: "Ctrls#21"
                            //             index: 2
                            //         }
                            //     }

                            //     // Here.DialControl {
                            //     //     objectName: "FilterType"
                            //     //     Layout.fillHeight: true
                            //     //     Layout.fillWidth: true
                            //     //     implicitWidth: height
                            //     //     highlightColor: "#de20ff"
                            //     //     controller {
                            //     //         category: "Synth 1 - DCF1#1"
                            //     //         index: 3
                            //     //     }
                            //     // }
                            // }
                            // }
                        }

                        // Item {
                        //     Layout.fillWidth: true
                        //     Layout.fillHeight: true
                        //     Layout.margins: 5

                        //     RowLayout {
                        //         anchors.fill: parent
                        //         spacing: 5
                        //         Here.SliderControl {
                        //             objectName: "AmpAttack"
                        //             Layout.fillHeight: true
                        //             Layout.fillWidth: true
                        //             slider.orientation: Qt.Vertical

                        //             controller {
                        //                 category: "Ctrls#1"
                        //                 index: 1
                        //             }
                        //         }

                        //         Here.SliderControl {
                        //             objectName: "AmpRelease"
                        //             Layout.fillHeight: true
                        //             Layout.fillWidth: true
                        //             slider.orientation: Qt.Vertical

                        //             controller {
                        //                 category: "Ctrls#1"
                        //                 index: 3
                        //             }
                        //         }
                        //     }


                    }
                }
            }
        }
    }
}

