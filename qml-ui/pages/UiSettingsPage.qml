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

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import io.zynthbox.ui 1.0 as Zynthian
import "../io/zynthbox/ui/private" as ZynthianPrivate

import org.kde.kirigami 2.4 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore

Zynthian.ScreenPage {
    //     Layout.fillWidth: true
    //     Layout.fillHeight: false
    //     QQC2.Label {
    //         Layout.fillWidth: false
    //         Layout.preferredWidth: Kirigami.Units.gridUnit * 12
    //         text: qsTr("Font Size")
    //     }
    //     QQC2.Slider {
    //         id: fontSizeSlider
    //         Layout.preferredWidth: Kirigami.Units.gridUnit * 20
    //         from: 1
    //         to: 100
    //         stepSize: 1
    //         value: zynqtgui.ui_settings.fontSize == null ? zynqtgui.theme_chooser.calculate_font_size() : zynqtgui.ui_settings.fontSize
    //         onPressedChanged: {
    //             // Set the value on release to save the value only when needed
    //             if (!pressed) {
    //                 zynqtgui.ui_settings.fontSize = value
    //             }
    //         }
    //     }
    //     Rectangle {
    //         Layout.preferredWidth: Kirigami.Units.gridUnit * 4
    //         Layout.preferredHeight: Kirigami.Units.gridUnit * 2
    //         Kirigami.Theme.inherit: false
    //         Kirigami.Theme.colorSet: Kirigami.Theme.Button
    //         color: Kirigami.Theme.backgroundColor
    //         border.color: "#ff999999"
    //         border.width: 2
    //         radius: 4
    //highlighted: view.activeFocus || zynqtgui.current_screen_id === root.screenId || (zynqtgui.current_screen_id === "layer" && root.screenId === "fixed_layers")
    //         QQC2.Label {
    //             anchors.centerIn: parent
    //             text: qsTr("%1 pt").arg(fontSizeSlider.value)
    //         }
    //     }
    // }

    id: root

    property int currentIndex: 0
    readonly property int count: content.children.length
    property var cuiaCallback: function(cuia) {
        // case "KNOB3_TOUCHED":
        // case "KNOB3_RELEASED":
        //     root.currentControl().clicked();
        //     return true;

        switch (cuia) {
        case "SELECT_DOWN":
        case "KNOB3_UP":
            root.incrementCurrentIndex();
            return true;
        case "SELECT_UP":
        case "KNOB3_DOWN":
            root.decrementCurrentIndex();
            return true;
        case "KNOB0_UP":
            root.currentControl().incrementValue();
            return true;
        case "KNOB0_DOWN":
            root.currentControl().decrementValue();
            return true;
        }
        return false;
    }

    function incrementCurrentIndex() {
        if (root.currentIndex + 1 === root.count)
            root.currentIndex = 0;
        else
            root.currentIndex++;
    }

    function decrementCurrentIndex() {
        if (root.currentIndex === 0)
            root.currentIndex = root.count - 1;
        else
            root.currentIndex--;
    }

    function currentControl() {
        return content.children[root.currentIndex];
    }

    title: qsTr("UI Settings")
    screenId: "ui_settings"
    contextualActions: []

    component EntryDelegate: QQC2.ItemDelegate {
        id: _delegate

        default property alias content: _controlContainer.data
        property alias infoText: _label2.text
        property int index: -1

        signal incrementValue()
        signal decrementValue()

        checkable: false
        highlighted: index === root.currentIndex
        width: parent.width
        implicitHeight: _layout.implicitHeight + topPadding + bottomPadding
        padding: PlasmaCore.Theme.padding

        background: ZynthianPrivate.DelegateBackground {
            delegate: _delegate
            visible: delegate.highlighted
        }

        contentItem: RowLayout {
            id: _layout

            spacing: PlasmaCore.Theme.spacing

            QQC2.Label {
                Layout.fillWidth: true
                text: _delegate.text
            }

            Row {
                id: _controlContainer

                Layout.alignment: Qt.AlignRight
            }

            QQC2.Label {
                id: _label2

                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                horizontalAlignment: Qt.AlignHCenter

                background: Rectangle {
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    color: Kirigami.Theme.backgroundColor
                    border.color: "#ff999999"
                    border.width: 2
                    radius: PlasmaCore.Theme.radius
                }

            }

        }

    }

    contentItem: QQC2.ScrollView {
        contentHeight: content.implicitHeight
        leftPadding: background.leftPadding
        rightPadding: background.rightPadding
        topPadding: background.topPadding
        bottomPadding: background.bottomPadding
        QQC2.ScrollBar.horizontal.visible: false

        contentItem: Column {
            id: content

            spacing: PlasmaCore.Theme.padding

            EntryDelegate {
                text: qsTr("Double Click Threshold Amount")
                infoText: qsTr("%1 ms").arg(doubleClickThresholdSlider.value)
                index: 0
                onIncrementValue: doubleClickThresholdSlider.increase()
                onDecrementValue: doubleClickThresholdSlider.decrease()

                QQC2.Slider {
                    id: doubleClickThresholdSlider

                    width: Kirigami.Units.gridUnit * 20
                    from: 0
                    to: 500
                    stepSize: 1
                    value: zynqtgui.ui_settings.doubleClickThreshold
                    onPressedChanged: {
                        // Set the value on release to save the value only when needed
                        if (!pressed)
                            zynqtgui.ui_settings.doubleClickThreshold = value;

                    }
                }

            }

            EntryDelegate {
                text: qsTr("Hardware Sequencer Interaction")
                infoText: zynqtgui.ui_settings.hardwareSequencer ? qsTr("Enabled") : qsTr("Disabled")
                onClicked: zynqtgui.ui_settings.hardwareSequencer = !zynqtgui.ui_settings.hardwareSequencer
                index: 1
                onIncrementValue: zynqtgui.ui_settings.hardwareSequencer = true
                onDecrementValue: zynqtgui.ui_settings.hardwareSequencer = false

                QQC2.Switch {
                    id: _switch1

                    checked: zynqtgui.ui_settings.hardwareSequencer
                    onClicked: {
                        zynqtgui.ui_settings.hardwareSequencer = checked;
                    }
                }

            }

            EntryDelegate {
                text: qsTr("Debug Mode")
                infoText: zynqtgui.ui_settings.debugMode ? qsTr("Enabled") : qsTr("Disabled")
                onClicked: zynqtgui.ui_settings.debugMode = !zynqtgui.ui_settings.debugMode
                index: 2
                onIncrementValue: zynqtgui.ui_settings.debugMode = true
                onDecrementValue: zynqtgui.ui_settings.debugMode = false

                QQC2.Switch {
                    checked: zynqtgui.ui_settings.debugMode
                    onClicked: {
                        zynqtgui.ui_settings.debugMode = checked;
                    }
                }

            }

            EntryDelegate {
                text: qsTr("Show Cursor")
                infoText: zynqtgui.ui_settings.showCursor ? qsTr("Enabled") : qsTr("Disabled")
                onClicked: zynqtgui.ui_settings.showCursor = !zynqtgui.ui_settings.showCursor
                index: 3
                onIncrementValue: zynqtgui.ui_settings.showCursor = true
                onDecrementValue: zynqtgui.ui_settings.showCursor = false

                QQC2.Switch {
                    checked: zynqtgui.ui_settings.showCursor
                    onClicked: {
                        zynqtgui.ui_settings.showCursor = checked;
                    }
                }

            }

        }

        background: ZynthianPrivate.SelectorViewBackground {
            id: background
        }

    }

}
