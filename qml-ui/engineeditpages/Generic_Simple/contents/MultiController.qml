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
import "." as Here
import QtGraphicalEffects 1.15

QQC2.Control {

    id: root
    enabled: controllersIds.length > 0
    opacity: enabled ? 1 : 0.5
    property var controllersIds : []
    default property alias content : _container.data

    property double value : 0.0
    property double from: 0.0
    property double to : 0.0

    property color highlightColor : "#5765f2"
    property color backgroundColor: "#333"
    property color foregroundColor: "#fafafa"
    property color alternativeColor :  "#16171C"

    property bool highlighted : false

    property alias title : _label1.text
    readonly property string displayText : (value / to).toFixed(2)

    Repeater {
        id: watcher
        model: root.controllersIds
        // onCountChanged: calculate()

        delegate: Item {
            id:  controlRoot
            objectName: "Controller#"+index
            property string category : modelData.split("|")[0]
            property int cindex : modelData.split("|")[1]
            property int mindex: index

            Here.ControllerGroup {
                id: controller
                category: controlRoot.category
                index: controlRoot.cindex
            }

            readonly property var value : controller.ctrl.value
            readonly property QtObject ctrl : controller.ctrl

            onCtrlChanged: calculate()
            onValueChanged: {
                if(root.visible)
                    calculate()
            }
        }
    }

    contentItem: Item {
        ColumnLayout {
            anchors.fill: parent

            QQC2.Label {
                id: _label1
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.capitalization: Font.AllUppercase
                font.weight: Font.DemiBold
                font.family: "Hack"
                font.pointSize: 9
                color: root.foregroundColor
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ColumnLayout {
                    id: _container
                    anchors.fill: parent

                }
            }

            QQC2.Label {
                visible: enabled
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.displayText
                font.capitalization: Font.AllUppercase
                font.weight: Font.DemiBold
                font.family: "Hack"
                font.pointSize: 9
                fontSizeMode: Text.Fit
                minimumPointSize: 6
                wrapMode: Text.NoWrap

                font.letterSpacing: 2
                color: root.foregroundColor
                padding: 4

                background: Rectangle {

                    border.width: 2
                    border.color: root.backgroundColor
                    color: root.alternativeColor
                    radius: 4

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1

                        visible: false
                        id: _recLabel
                        color: root.highlighted ? root.highlightColor : root.alternativeColor
                        border.color: Qt.darker(color, 2)
                        radius: 4

                    }

                    InnerShadow {
                        anchors.fill: _recLabel
                        radius: 8.0
                        samples: 16
                        horizontalOffset: -3
                        verticalOffset: 1
                        color: "#b0000000"
                        source: _recLabel
                    }
                }
            }

            QQC2.Pane {
                visible: enabled
                Layout.fillWidth: true
                padding: 4
                contentItem: Column {
                    Repeater {
                        model: watcher.count

                        delegate: Text {

                            property Item obj : watcher.itemAt(modelData)
                            width: parent.width
                            color: root.foregroundColor
                            text:  obj.ctrl.title + " : " + obj.ctrl.value.toFixed(2) + " | " + (obj.ctrl.value/obj.ctrl.max_value).toFixed(2)
                            font.pointSize: 6
                        }
                    }
                }

                background: Rectangle {

                    border.width: 2
                    border.color: root.alternativeColor
                    color: root.backgroundColor
                    radius: 4

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1

                        visible: false
                        id: _infoRec
                        color: root.alternativeColor
                        border.color: Qt.darker(color, 2)
                        radius: 4

                    }

                    InnerShadow {
                        anchors.fill: _infoRec
                        radius: 8.0
                        samples: 16
                        horizontalOffset: -3
                        verticalOffset: 1
                        color: "#b0000000"
                        source: _infoRec
                    }
                }
            }

        }
    }

    onVisibleChanged: {
        if(visible)
            calculate()
    }

    // Component.onCompleted: {
    //     var i = 0
    //     var fromValue = 0.0
    //     var toValue = 0.0

    //     for (i; i < controllers.length; i++) {
    //         fromValue += controllers[i].ctrl.max_value
    //         toValue += controllers[i].ctrl.max_value
    //     }

    //     root.from = fromValue/i
    //     root.to = toValue/i
    // }

    function calculate() {
        if(!root.visible)
            return;

        var sumValue = 0.0
        var fromValue = 0.0
        var toValue = 0.0

        var i = 0
        for (i; i < watcher.count; i++) {
            var item = watcher.itemAt(i)
            sumValue += item.ctrl.value
            console.log("Calculating medium controllers value", sumValue, item.objectName )
            fromValue += item.ctrl.value0
            toValue += item.ctrl.max_value
        }

        var mediumValue = sumValue / i
        root.value = mediumValue
        root.valueChanged()

        root.from = fromValue/i
        root.to = toValue/i
        console.log("Calculating medium controllers value", sumValue, root.from, root.to )

        console.log("Calculating medium controllers value", mediumValue)

    }

    function setValue(value) {
        if(value === root.value)
            return

        // var percent = value / root.to
        var i = 0
        for (i; i < watcher.count; i++) {
            watcher.itemAt(i).ctrl.value = value
        }

        calculate()
    }
}
