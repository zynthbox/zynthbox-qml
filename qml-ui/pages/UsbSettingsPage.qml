/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Main Class and Program for Zynthian GUI

Copyright (C) 2026 Dan Leinir Turthra Jensen <admin@leinir.dk>

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


import io.zynthbox.ui 1.0 as ZUI

import org.kde.kirigami 2.4 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore

ZUI.ScreenPage {

    id: root

    property int currentIndex: 0
    onCurrentIndexChanged: {
        if (-1 < currentIndex) {
            scrollView.ensureVisible(content.children[currentIndex]);
        }
    }
    readonly property int count: content.children.length
    property var cuiaCallback: function(cuia) {

        switch (cuia) {
        case "SWITCH_ARROW_DOWN_RELEASED":
        case "KNOB3_UP":
            root.incrementCurrentIndex();
            return true;
        case "SWITCH_ARROW_UP_RELEASED":
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

    title: qsTr("USB Gadget Settings")
    screenId: "usb_settings"

    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
        opacity: 0.4
    }

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
        padding: ZUI.Theme.padding

        background: ZUI.DelegateBackground {
            delegate: _delegate
            visible: delegate.highlighted
        }

        contentItem: RowLayout {
            id: _layout

            spacing: ZUI.Theme.spacing

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

                Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                horizontalAlignment: Qt.AlignHCenter

                background: Rectangle {
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    color: Kirigami.Theme.backgroundColor
                    border.color: "#ff999999"
                    border.width: 2
                    radius: ZUI.Theme.radius
                }

            }

        }

    }

    contentItem: QQC2.ScrollView {
        id: scrollView
        leftPadding: background.leftPadding
        rightPadding: background.rightPadding
        topPadding: background.topPadding
        bottomPadding: background.bottomPadding
        QQC2.ScrollBar.horizontal.visible: false
        function ensureVisible(item) {
            var ypos = item.mapToItem(content, 0, 0).y
            var ext = item.height + ypos
            if ( ypos < flickableItem.contentY // begins before
                || ypos > flickableItem.contentY + flickableItem.height // begins after
                || ext < flickableItem.contentY // ends before
                || ext > flickableItem.contentY + flickableItem.height) { // ends after
                // don't exceed bounds
                flickableItem.contentY = Math.max(0, Math.min(ypos - flickableItem.height + item.height + Kirigami.Units.largeSpacing * 4, content.height - flickableItem.height))
            }
        }
        Flickable {
            id: flickableItem
            contentWidth: content.width
            contentHeight: content.height
            flickableDirection: Flickable.VerticalFlick
            Column {
                id: content
                width: scrollView.availableWidth - ZUI.Theme.padding
                spacing: ZUI.Theme.padding

                EntryDelegate {
                    text: qsTr("USB Audio Interface Stereo Pairs")
                    infoText: zynqtgui.usb_settings.audioInterfaceStyle === 0
                        ? qsTr("None")
                        : zynqtgui.usb_settings.audioInterfaceStyle === 1
                            ? qsTr("Global Only")
                            : zynqtgui.usb_settings.audioInterfaceStyle === 2
                                ? qsTr("Global+Tracks")
                                : qsTr("Unused")
                    index: 0
                    onIncrementValue: zynqtgui.usb_settings.audioInterfaceStyle = Math.min(2, zynqtgui.usb_settings.audioInterfaceStyle + 1)
                    onDecrementValue: zynqtgui.usb_settings.audioInterfaceStyle = Math.max(0, zynqtgui.usb_settings.audioInterfaceStyle - 1)

                    QQC2.Slider {
                        width: Kirigami.Units.gridUnit * 20
                        from: 0
                        to: 2
                        stepSize: 1
                        value: zynqtgui.usb_settings.audioInterfaceStyle
                        onPressedChanged: {
                            // Set the value on release to save the value only when needed
                            if (!pressed)
                                zynqtgui.usb_settings.audioInterfaceStyle = value;
                        }
                    }
                }

                EntryDelegate {
                    text: qsTr("Per-track MIDI In/Out Port")
                    infoText: zynqtgui.usb_settings.midiPerTrack ? qsTr("Enabled") : qsTr("Disabled")
                    onClicked: zynqtgui.usb_settings.midiPerTrack = !zynqtgui.usb_settings.midiPerTrack
                    index: 1
                    onIncrementValue: zynqtgui.usb_settings.midiPerTrack = true
                    onDecrementValue: zynqtgui.usb_settings.midiPerTrack = false

                    QQC2.Switch {
                        checked: zynqtgui.usb_settings.midiPerTrack
                        onClicked: {
                            zynqtgui.usb_settings.midiPerTrack = checked;
                        }
                    }
                }

                EntryDelegate {
                    text: qsTr("USB Ethernet Device (10.55.0.1)")
                    infoText: zynqtgui.usb_settings.ethernet ? qsTr("Enabled") : qsTr("Disabled")
                    onClicked: zynqtgui.usb_settings.ethernet = !zynqtgui.usb_settings.ethernet
                    index: 2
                    onIncrementValue: zynqtgui.usb_settings.ethernet = true
                    onDecrementValue: zynqtgui.usb_settings.ethernet = false

                    QQC2.Switch {
                        checked: zynqtgui.usb_settings.ethernet
                        onClicked: {
                            zynqtgui.usb_settings.ethernet = checked;
                        }
                    }
                }
            }
        }
    }

}
