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
        // case "KNOB3_TOUCHED":
        // case "KNOB3_RELEASED":
        //     root.currentControl().clicked();
        //     return true;

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

    title: qsTr("UI Settings")
    screenId: "ui_settings"
    contextualActions: [Kirigami.Action {
        text: "Reload"
        onTriggered: _testingLoader.reset()
        visible: _stackLayout.currentIndex ===1
    }, Kirigami.Action {
        text: "Info"
        onTriggered: _testingLoader.info()
        visible: _stackLayout.currentIndex === 1
    }, Kirigami.Action {
        text: "Exit"
        onTriggered: _stackLayout.currentIndex = 0
        visible: _stackLayout.currentIndex === 1
    }
    ]

    background: Rectangle 
    {
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

    contentItem: StackLayout {
        id: _stackLayout
        QQC2.ScrollView {
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
                        text: qsTr("Record Button Interaction Style")
                        infoText: zynqtgui.ui_settings.recordButtonInteractionStyle === 0
                            ? qsTr("Dialog")
                            : zynqtgui.ui_settings.recordButtonInteractionStyle === 1
                                ? qsTr("Immediate")
                                : qsTr("Unknown")
                        index: 1
                        onIncrementValue: zynqtgui.ui_settings.recordButtonInteractionStyle = Math.min(1, zynqtgui.ui_settings.recordButtonInteractionStyle + 1)
                        onDecrementValue: zynqtgui.ui_settings.recordButtonInteractionStyle = Math.max(0, zynqtgui.ui_settings.recordButtonInteractionStyle - 1)

                        QQC2.Slider {
                            width: Kirigami.Units.gridUnit * 20
                            from: 0
                            to: 1
                            stepSize: 1
                            value: zynqtgui.ui_settings.recordButtonInteractionStyle
                            onPressedChanged: {
                                // Set the value on release to save the value only when needed
                                if (!pressed)
                                    zynqtgui.ui_settings.recordButtonInteractionStyle = value;
                            }
                        }
                    }

                    EntryDelegate {
                        text: qsTr("Hardware Sequencer Interaction")
                        infoText: zynqtgui.ui_settings.hardwareSequencer ? qsTr("Enabled") : qsTr("Disabled")
                        onClicked: zynqtgui.ui_settings.hardwareSequencer = !zynqtgui.ui_settings.hardwareSequencer
                        index: 2
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
                        text: qsTr("Hardware Sequencer Auto-Preview")
                        infoText: zynqtgui.ui_settings.hardwareSequencerPreviewStyle === 0
                            ? qsTr("When Stopped")
                            : zynqtgui.ui_settings.hardwareSequencerPreviewStyle === 1
                                ? qsTr("Always")
                                : zynqtgui.ui_settings.hardwareSequencerPreviewStyle === 2
                                    ? qsTr("Never")
                                    : qsTr("Step Release")
                        index: 3
                        onIncrementValue: zynqtgui.ui_settings.hardwareSequencerPreviewStyle = Math.min(3, zynqtgui.ui_settings.hardwareSequencerPreviewStyle + 1)
                        onDecrementValue: zynqtgui.ui_settings.hardwareSequencerPreviewStyle = Math.max(0, zynqtgui.ui_settings.hardwareSequencerPreviewStyle - 1)

                        QQC2.Slider {
                            width: Kirigami.Units.gridUnit * 20
                            from: 0
                            to: 3
                            stepSize: 1
                            value: zynqtgui.ui_settings.hardwareSequencerPreviewStyle
                            onPressedChanged: {
                                // Set the value on release to save the value only when needed
                                if (!pressed)
                                    zynqtgui.ui_settings.hardwareSequencerPreviewStyle = value;
                            }
                        }
                    }

                    EntryDelegate {
                        text: qsTr("Hardware Sequencer Edit Step Notes")
                        infoText: zynqtgui.ui_settings.hardwareSequencerEditInclusions === 0
                            ? qsTr("Selection")
                            : qsTr("All Entries")
                        index: 4
                        onIncrementValue: zynqtgui.ui_settings.hardwareSequencerEditInclusions = Math.min(1, zynqtgui.ui_settings.hardwareSequencerEditInclusions + 1)
                        onDecrementValue: zynqtgui.ui_settings.hardwareSequencerEditInclusions = Math.max(0, zynqtgui.ui_settings.hardwareSequencerEditInclusions - 1)

                        QQC2.Switch {
                            checked: zynqtgui.ui_settings.hardwareSequencerEditInclusions === 1
                            onClicked: {
                                zynqtgui.ui_settings.hardwareSequencerEditInclusions = checked ? 1 : 0;
                            }
                        }
                        // QQC2.Slider {
                        //     width: Kirigami.Units.gridUnit * 20
                        //     from: 0
                        //     to: 1
                        //     stepSize: 1
                        //     value: zynqtgui.ui_settings.hardwareSequencerEditInclusions
                        //     onPressedChanged: {
                        //         // Set the value on release to save the value only when needed
                        //         if (!pressed)
                        //             zynqtgui.ui_settings.hardwareSequencerEditInclusions = value;
                        //     }
                        // }
                    }

                    EntryDelegate {
                        text: qsTr("Record Live When Holding Record")
                        infoText: zynqtgui.ui_settings.temporaryLiveRecordStyle === 0
                            ? qsTr("Off")
                            : zynqtgui.ui_settings.temporaryLiveRecordStyle === 1
                                ? qsTr("When Held")
                                : zynqtgui.ui_settings.temporaryLiveRecordStyle === 2
                                    ? qsTr("Sticky")
                                    : qsTr("Unknown")
                        index: 5
                        onIncrementValue: zynqtgui.ui_settings.temporaryLiveRecordStyle = Math.min(2, zynqtgui.ui_settings.temporaryLiveRecordStyle + 1)
                        onDecrementValue: zynqtgui.ui_settings.temporaryLiveRecordStyle = Math.max(0, zynqtgui.ui_settings.temporaryLiveRecordStyle - 1)

                        QQC2.Slider {
                            width: Kirigami.Units.gridUnit * 20
                            from: 0
                            to: 2
                            stepSize: 1
                            value: zynqtgui.ui_settings.temporaryLiveRecordStyle
                            onPressedChanged: {
                                // Set the value on release to save the value only when needed
                                if (!pressed)
                                    zynqtgui.ui_settings.temporaryLiveRecordStyle = value;
                            }
                        }
                    }

                    EntryDelegate {
                        text: qsTr("Debug Mode")
                        infoText: zynqtgui.ui_settings.debugMode ? qsTr("Enabled") : qsTr("Disabled")
                        onClicked: zynqtgui.ui_settings.debugMode = !zynqtgui.ui_settings.debugMode
                        index: 6
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
                        text: qsTr("Show Experimental Features")
                        infoText: zynqtgui.ui_settings.showExperimentalFeatures ? qsTr("Enabled") : qsTr("Disabled")
                        onClicked: zynqtgui.ui_settings.showExperimentalFeatures = !zynqtgui.ui_settings.showExperimentalFeatures
                        index: 7
                        onIncrementValue: zynqtgui.ui_settings.showExperimentalFeatures = true
                        onDecrementValue: zynqtgui.ui_settings.showExperimentalFeatures = false

                        QQC2.Switch {
                            checked: zynqtgui.ui_settings.showExperimentalFeatures
                            onClicked: {
                                zynqtgui.ui_settings.showExperimentalFeatures = checked;
                            }
                        }

                    }

                    EntryDelegate {
                        text: qsTr("Show Cursor")
                        infoText: zynqtgui.ui_settings.showCursor ? qsTr("Enabled") : qsTr("Disabled")
                        onClicked: zynqtgui.ui_settings.showCursor = !zynqtgui.ui_settings.showCursor
                        index: 8
                        onIncrementValue: zynqtgui.ui_settings.showCursor = true
                        onDecrementValue: zynqtgui.ui_settings.showCursor = false

                        QQC2.Switch {
                            checked: zynqtgui.ui_settings.showCursor
                            onClicked: {
                                zynqtgui.ui_settings.showCursor = checked;
                            }
                        }

                    }

                    EntryDelegate {
                        text: qsTr("Encoder Touch Response")
                        infoText: zynqtgui.ui_settings.touchEncoders ? qsTr("Enabled") : qsTr("Disabled")
                        onClicked: zynqtgui.ui_settings.touchEncoders = !zynqtgui.ui_settings.touchEncoders
                        index: 9
                        onIncrementValue: zynqtgui.ui_settings.touchEncoders = true
                        onDecrementValue: zynqtgui.ui_settings.touchEncoders = false

                        QQC2.Switch {
                            checked: zynqtgui.ui_settings.touchEncoders
                            onClicked: {
                                zynqtgui.ui_settings.touchEncoders = checked;
                            }
                        }

                    }


                    EntryDelegate {
                        text: qsTr("VNC Server")
                        infoText: zynqtgui.ui_settings.vncserverEnabled ? qsTr("Enabled") : qsTr("Disabled")
                        onClicked: zynqtgui.ui_settings.vncserverEnabled = !zynqtgui.ui_settings.vncserverEnabled
                        index: 10
                        onIncrementValue: zynqtgui.ui_settings.vncserverEnabled = true
                        onDecrementValue: zynqtgui.ui_settings.vncserverEnabled = false

                        QQC2.Switch {
                            checked: zynqtgui.ui_settings.vncserverEnabled
                            onClicked: {
                                zynqtgui.ui_settings.vncserverEnabled = checked;
                            }
                        }
                    }

                    EntryDelegate {
                        visible: zynqtgui.ui_settings.debugMode // Hide QML Testing loader when debugMode is off
                        text: qsTr("QML Testing Loader")
                        infoText:  "Load"
                        index: 11
                        onClicked: _stackLayout.currentIndex = 1
                    }

                    EntryDelegate {
                        text: qsTr("LED Brightness")
                        infoText: qsTr("%1% ").arg(zynqtgui.ui_settings.ledBrightness)
                        index: 12
                        onIncrementValue: zynqtgui.ui_settings.ledBrightness = Math.min(100, zynqtgui.ui_settings.ledBrightness + 1)
                        onDecrementValue: zynqtgui.ui_settings.ledBrightness = Math.max(0, zynqtgui.ui_settings.ledBrightness - 1)

                        QQC2.Slider {
                            width: Kirigami.Units.gridUnit * 20
                            from: 0
                            to: 100
                            stepSize: 1
                            value: zynqtgui.ui_settings.ledBrightness
                            onValueChanged: {
                                zynqtgui.ui_settings.ledBrightness = value;
                            }
                        }
                    }

                    Repeater {
                        model: zynqtgui.ui_settings.displays
                        EntryDelegate {
                            text: qsTr("Display '%1' Brightness").arg(modelData.name)
                            infoText: qsTr("%1 / %2").arg(modelData.brightness).arg(modelData.max_brightness)
                            index: 13 + model.index
                            onIncrementValue: modelData.brightness = Math.min(modelData.max_brightness, modelData.brightness + 1)
                            onDecrementValue: modelData.brightness = Math.max(0, modelData.brightness - 1)

                            QQC2.Slider {
                                width: Kirigami.Units.gridUnit * 20
                                from: 0
                                to: modelData.max_brightness
                                stepSize: 1
                                value: modelData.brightness
                                onValueChanged: {
                                    modelData.brightness = value;
                                }
                            }
                        }
                    }
                }
            }
            background: ZUI.SelectorViewBackground {
                id: background
            }
        }

        Loader {
            id: _testingLoader
            active: false
            asynchronous: true

            ZUI.Popup {
                id: _testingLoaderInfoDialog
                modal: true
                height: 200

                contentItem: QQC2.Label {
                    id: _infoLabel
                    text: "How to use:\n
                To set the entry file to watch and load:\n
                >> echo 'main.qml' > /ZB_QML_TEST_FILE\n
                The current entry file is set to:\n"+zynqtgui.ui_settings.qmlTestFile 
                }
            }

            property Component comp : null

            function info() {
                _testingLoaderInfoDialog.open()
            }
            function reset() {    
                var source = String(zynqtgui.ui_settings.qmlTestFile)

                if(source.length == 0)
                    return

                _testingLoader.active= false
                console.log("RESET THE TEST QML FILE")
                if(_testingLoader.comp)
                    _testingLoader.comp.destroy()
                _testingLoader.comp = Qt.createComponent(zynqtgui.ui_settings.qmlTestFile + "?reload=" + new Date().getTime())
                if (_testingLoader.comp.status === Component.Ready) {
                    _testingLoader.sourceComponent = _testingLoader.comp
                    _testingLoader.active = true
                    _debugText.text = ""
                } else {
                    console.log("Component status is not ready:", _testingLoader.comp.status);
                    _debugText.text= _testingLoader.comp.errorString()
                }                
            }

            Connections{
                target: zynqtgui.ui_settings
                onQmlTestFileChanged: _testingLoader.reset()
                onQmlTestFileModified: _testingLoader.reset()
            }

            QQC2.Label {
                id: _debugText
                anchors.centerIn: parent
                anchors.fill: parent
                anchors.margins: Kirigami.Units.gridUnit*2
                color: "white"
            }

            QQC2.Button {
                text: "Load"
                visible: !_testingLoader.active
                onClicked: _testingLoader.reset()
                anchors.centerIn: parent
                height: Kirigami.Units.gridUnit * 1.5
                width: Kirigami.Units.gridUnit * 4
            }
        }
    }

}
