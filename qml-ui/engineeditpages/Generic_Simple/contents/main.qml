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
import QtQml 2.15
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import "." as Here
import Zynthian 1.0 as Zynthian
import QtGraphicalEffects 1.15

Item {
    id: root

    readonly property var synthMap : {
        'synthv1': {
            'cutoff': ['Synth 1 - DCF1#1|1','Synth 2 - DCF2#1|1'],
            'filterAttack' : ['Synth 1 - DCF1#2|2', 'Synth 2 - DCF2#2|2'],
            'filterRelease' : ['Synth 1 - DCF1#3|1', 'Synth 2 - DCF2#3|1'],
            'ampAttack' : ['Synth 1 - DCA1#1|1', 'Synth 2 - DCA2#1|1'],
            'ampRelease' : ['Synth 1 - DCA1#2|0', 'Synth 2 - DCA2#2|0']},
        'Obxd': {'cutoff': ['Ctrls#12|0'], 'filterAttack' : []},
        'Helm': {'cutoff': ['Ctrls#4|2'], 'filterAttack' : []},
        'Nekobi': {'cutoff': ['Ctrls#1|2'], 'filterAttack' : []},
        'Surge': {'cutoff': ['Ctrls#51|0', 'Ctrls#52|2','Ctrls#118|3','Ctrls#120|1'], 'filterAttack' : []},
        'Calf Monosynth': {'cutoff': ['Ctrls#3|1'], 'filterAttack' : []}
    }

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

                        text: _multiCutoffController.value
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
                        text: zynqtgui.curlayerEngineName
                        Layout.alignment: Qt.AlignTop
                        // font.capitalization: Font.AllUppercase
                        font.weight: Font.ExtraBold
                        font.family: "Hack"
                        font.pointSize: 20
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 5

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 5

                        RowLayout {
                            anchors.fill: parent
                            spacing: 5

                            Here.MultiController {
                                id: _multiFilterAttackController
                                highlightColor: "#de20ff"
                                title: "Filter Attack"
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                highlighted : _slider.pressed
                                controllersIds: root.synthMap[zynqtgui.curlayerEngineName].filterAttack ? root.synthMap[zynqtgui.curlayerEngineName].filterAttack : []

                                Here.Slider {
                                    id: _slider
                                    objectName: "FilterAttack"
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignCenter
                                    orientation: Qt.Vertical
                                    highlightColor: _multiFilterAttackController.highlightColor
                                    from:_multiFilterAttackController.from
                                    to:_multiFilterAttackController.to
                                    value: _multiFilterAttackController.value
                                    onMoved:_multiFilterAttackController.setValue(value)
                                }
                            }

                            Here.MultiController {
                                id: _multiFilterReleaseController
                                highlightColor: "#de20ff"
                                title: "Filter Release"
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                highlighted : _sliderFRel.pressed
                                controllersIds: root.synthMap[zynqtgui.curlayerEngineName].filterRelease ? root.synthMap[zynqtgui.curlayerEngineName].filterRelease : []


                                Here.Slider {
                                    id: _sliderFRel
                                    objectName: "FilterAttack"
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignCenter
                                    orientation: Qt.Vertical
                                    highlightColor: _multiFilterReleaseController.highlightColor
                                    from:_multiFilterReleaseController.from
                                    to:_multiFilterReleaseController.to
                                    value: _multiFilterReleaseController.value
                                    onMoved:_multiFilterReleaseController.setValue(value)
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 5

                        ColumnLayout {

                            anchors.fill: parent
                            spacing: 5

                            Here.MultiController {
                                id: _multiCutoffController
                                // highlightColor: "#de20ff"
                                title: "Cutoff"
                                Layout.alignment: Qt.AlignCenter
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                // highlighted : _cutoffDial.pressed
                                controllersIds: root.synthMap[zynqtgui.curlayerEngineName] ? root.synthMap[zynqtgui.curlayerEngineName].cutoff : []

                                Here.Dial {
                                    id: _cutoffDial
                                    text: _multiCutoffController.displayText
                                    implicitWidth: height
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignCenter
                                    // orientation: Qt.Vertical
                                    highlightColor: _multiCutoffController.highlightColor
                                    from: _multiCutoffController.from
                                    to: _multiCutoffController.to
                                    value: _multiCutoffController.value > 0 ?_multiCutoffController.value  : 0
                                    onMoved:_multiCutoffController.setValue(value)

                                    onVisibleChanged: {
                                        _cutoffDial.value = Qt.binding(()=>{return _multiCutoffController.value})
                                    }

                                    Component.onCompleted: {
                                        _cutoffDial.value = Qt.binding(()=>{return _multiCutoffController.value})
                                    }
                                }

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

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 5

                        RowLayout {
                            anchors.fill: parent
                            spacing: 5
                            Here.MultiController {
                                id: _multiAmpAttackController
                                highlightColor: "#de20ff"
                                title: "Amp Attack"
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                highlighted : _sliderAAtack.pressed
                                controllersIds: root.synthMap[zynqtgui.curlayerEngineName].ampAttack ? root.synthMap[zynqtgui.curlayerEngineName].ampAttack : []

                                Here.Slider {
                                    id: _sliderAAtack
                                    objectName: "FilterAttack"
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignCenter
                                    orientation: Qt.Vertical
                                    highlightColor: _multiAmpAttackController.highlightColor
                                    from:_multiAmpAttackController.from
                                    to:_multiAmpAttackController.to
                                    value: _multiAmpAttackController.value
                                    onMoved:_multiAmpAttackController.setValue(value)
                                }
                            }

                            Here.MultiController {
                                id: _multiAmpReleaseController
                                highlightColor: "#de20ff"
                                title: "Amp Release"
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                highlighted : _sliderARel.pressed
                                controllersIds: root.synthMap[zynqtgui.curlayerEngineName].ampRelease  ? root.synthMap[zynqtgui.curlayerEngineName].ampRelease : []


                                Here.Slider {
                                    id: _sliderARel
                                    objectName: "FilterAttack"
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignCenter
                                    orientation: Qt.Vertical
                                    highlightColor: _multiAmpReleaseController.highlightColor
                                    from:_multiAmpReleaseController.from
                                    to:_multiAmpReleaseController.to
                                    value: _multiAmpReleaseController.value
                                    onMoved:_multiAmpReleaseController.setValue(value)
                                }
                            }
                        }


                    }
                }
            }
        }
    }
}


