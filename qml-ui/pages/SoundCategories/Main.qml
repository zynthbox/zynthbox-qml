/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Snth Categories Page

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
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import '../../Zynthian' 1.0 as Zynthian
import '../Sketchpad' as Sketchpad

Zynthian.ScreenPage {
    id: root

    property QtObject selectedChannel: applicationWindow().selectedChannel
    property QtObject soundCopySource
    /**
      * This signal will be emitted when some other page wants to
      * open the sound saving dialog
      */
    signal showSaveSoundDialog()

    title: qsTr("Sound Categories")
    screenId: "sound_categories"
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8
    onShowSaveSoundDialog: {
        saveSoundDialog.fileName = zynqtgui.sound_categories.suggestedSoundFileName()
        saveSoundDialog.open()
    }
    contextualActions: [
        Kirigami.Action {
            text: qsTr("Move/Paste")

            Kirigami.Action {
                enabled: root.soundCopySource == null &&
                         soundButtonGroup.checkedButton != null &&
                         soundButtonGroup.checkedButton.checked
                text: qsTr("Move")
                onTriggered: {
                    // root.soundCopySource = soundButtonGroup.checkedButton.soundObj
                }
            }
            Kirigami.Action {
                enabled: root.soundCopySource != null &&
                         categoryButtonGroup.checkedButton &&
                         categoryButtonGroup.checkedButton.category !== "*" &&
                         categoryButtonGroup.checkedButton.category !== root.soundCopySource.category
                text: qsTr("Paste")
                onTriggered: {
                    // root.soundCopySource.category = categoryButtonGroup.checkedButton.category
                    // root.soundCopySource = null
                }
            }
            Kirigami.Action {
                enabled: root.soundCopySource != null
                text: qsTr("Cancel")
                onTriggered: {
                    // root.soundCopySource = null
                }
            }
            Kirigami.Action {
                enabled: soundButtonGroup.checkedButton != null &&
                         soundButtonGroup.checkedButton.checked &&
                         soundButtonGroup.checkedButton.soundObj.category !== "0"
                text: qsTr("Clear Category")
                onTriggered: {
                    // soundButtonGroup.checkedButton.soundObj.category = "0"
                }
            }
        },
        Kirigami.Action {
            // True when action acts as save button, false when acts as load button
            property bool isSaveBtn: soundButtonGroup.checkedButton == null || !soundButtonGroup.checkedButton.checked

            enabled: root.soundCopySource == null
            text: isSaveBtn
                    ? qsTr("Save")
                    : qsTr("Load")
            onTriggered: {
                if (isSaveBtn) {
                    saveSoundDialog.fileName = zynqtgui.sound_categories.suggestedSoundFileName()
                    saveSoundDialog.open()
                } else {
                    zynqtgui.sound_categories.loadSound(soundButtonGroup.checkedButton.soundObj)
                }
            }
        },
        Kirigami.Action {
            enabled: soundButtonGroup.checkedButton && soundButtonGroup.checkedButton.checked
            text: qsTr("Clear Selection")
            onTriggered: {
                soundButtonGroup.checkedButton.checked = false
            }
        }
    ]

    cuiaCallback: function(cuia) {
        return false;
    }

    Connections {
        target: zynqtgui
        onCurrent_screen_idChanged: {
            // Refresh sounds model on page open
            if (zynqtgui.current_screen_id === root.screenId) {
                soundTypeComboBox.currentIndex = 0
                zynqtgui.sound_categories.setSoundTypeFilter(soundTypeComboBox.model[soundTypeComboBox.currentIndex])
                zynqtgui.sound_categories.load_sounds_model()

                if (soundButtonGroup.checkedButton && soundButtonGroup.checkedButton.checked) {
                    soundButtonGroup.checkedButton.checked = false
                }
            }
        }
    }

    Zynthian.SaveFileDialog {
        id: saveSoundDialog
        visible: false

        headerText: qsTr("Save Sound")
        conflictText: qsTr("Sound file exists")
        overwriteOnConflict: false

        onFileNameChanged: {
            fileCheckTimer.restart()
        }
        Timer {
            id: fileCheckTimer
            interval: 50
            onTriggered: {
                saveSoundDialog.conflict = zynqtgui.sound_categories.checkIfSoundFileExists(saveSoundDialog.fileName);
            }
        }

        onAccepted: {
            zynqtgui.sound_categories.saveSound(saveSoundDialog.fileName, categoryButtonGroup.checkedButton.category)
        }
    }
    
    contentItem : ColumnLayout {
        id: content

        // Top Row : Sound categories button and area to display sound files
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                Layout.fillWidth: false
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                spacing: 0

                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                    horizontalAlignment: Qt.AlignHCenter
                    verticalAlignment: Qt.AlignVCenter
                    text: qsTr("Categories")
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: 2
                }

                QQC2.ButtonGroup {
                    id: categoryButtonGroup
                    buttons: categoryButtons.children
                }

                ColumnLayout {
                    id: categoryButtons

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: spacing
                    spacing: content.rowSpacing

                    CategoryButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        category: "*"
                        checked: true
                    }

                    CategoryButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        category: "0"
                    }

                    CategoryButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        category: "3"
                    }

                    CategoryButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        category: "2"
                    }

                    CategoryButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        category: "4"
                    }

                    CategoryButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        category: "5"
                    }

                    CategoryButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        category: "1"
                    }

                    CategoryButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        category: "99"
                    }
                }
            }

            ColumnLayout {
                id: soundsDisplayContainer
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                    Layout.alignment: Qt.AlignCenter

                    QQC2.ComboBox {
                        id: soundTypeComboBox
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        model: ["my-sounds", "community-sounds"]
                        onActivated: {
                            zynqtgui.sound_categories.setSoundTypeFilter(model[index])
                        }
                        delegate: QQC2.ItemDelegate {
                            id: itemDelegate
                            width: parent.width
                            text: soundTypeComboBox.textRole ? (Array.isArray(soundTypeComboBox.model) ? modelData[soundTypeComboBox.textRole] : model[soundTypeComboBox.textRole]) : modelData
                            font.weight: soundTypeComboBox.currentIndex === index ? Font.DemiBold : Font.Normal
                            highlighted: soundTypeComboBox.highlightedIndex === index
                            hoverEnabled: soundTypeComboBox.hoverEnabled
                            contentItem: QQC2.Label {
                                text: itemDelegate.text
                                font: itemDelegate.font
                                elide: QQC2.Label.ElideRight
                                verticalAlignment: QQC2.Label.AlignVCenter
                                horizontalAlignment: QQC2.Label.AlignHCenter
                            }
                        }
                    }

                    QQC2.Button {
                        Layout.fillHeight: true
                        Layout.preferredWidth: height
                        onClicked: zynqtgui.sound_categories.load_sounds_model()

                        Kirigami.Icon {
                            anchors.fill: parent
                            anchors.margins: 4
                            source: Qt.resolvedUrl("../../../img/refresh.svg")
                            color: "#ffffffff"
                        }
                    }
                }

                Flickable {
                    id: scrollView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    // Take into consideration the top and bottom margin of Kirigami.Units.gridUnit each
                    contentHeight: soundGrid.height + Kirigami.Units.gridUnit * 2
                    flickableDirection: Flickable.AutoFlickDirection
                    clip: true
                    QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                        width: Kirigami.Units.gridUnit
                        height: Kirigami.Units.gridUnit * 3
                        anchors.right: parent.right - width
                        policy: QQC2.ScrollBar.AlwaysOn
                    }
                    Item {
                        width: soundsDisplayContainer.width

                        QQC2.ButtonGroup {
                            id: soundButtonGroup
                            buttons: soundGrid.children
                        }

                        GridLayout {
                            id: soundGrid

                            property real cellWidth: (width - columnSpacing * (columns-1))/columns

                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                margins: Kirigami.Units.gridUnit
                            }

                            columns: 5
                            rowSpacing: Kirigami.Units.gridUnit
                            columnSpacing: Kirigami.Units.gridUnit

                            Repeater {
                                id: soundButtonsRepeater
                                model: zynqtgui.sound_categories.soundsModel
                                delegate: QQC2.Button {
                                    property QtObject soundObj: model.sound
                                    property bool wasChecked
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    Layout.preferredWidth: soundGrid.cellWidth
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 4.5
                                    checkable: true
                                    // Little bit of hula-hooping to allow unchecking buttons in an exclusive button group
                                    // Source : https://stackoverflow.com/a/51098266
                                    onPressed: wasChecked = checked
                                    onReleased: {
                                        if (wasChecked) {
                                            checked = false;
                                            toggled(); // emit the toggled signal manually, since we changed the checked value programmatically but it still originated as an user interaction.
                                        }
                                    }

                                    QQC2.Label {
                                        anchors.fill: parent
                                        text: model.display
                                        wrapMode: QQC2.Label.WrapAtWordBoundaryOrAnywhere
                                        horizontalAlignment: QQC2.Label.AlignHCenter
                                        verticalAlignment: QQC2.Label.AlignVCenter
                                    }

                                    QQC2.Label {
                                        anchors {
                                            right: parent.right
                                            bottom: parent.bottom
                                            margins: Kirigami.Units.gridUnit * 0.5
                                        }

                                        text: zynqtgui.sound_categories.getCategoryNameFromKey(soundObj.category)
                                        font.pointSize: 8
                                    }

                                    QQC2.Label {
                                        anchors {
                                            left: parent.left
                                            bottom: parent.bottom
                                            margins: Kirigami.Units.gridUnit * 0.5
                                        }

                                        text: zynqtgui.layer.load_layer_channels_from_json(soundObj.metadata.synthFxSnapshot).length
                                        font.pointSize: 8
                                    }
                                }
                            }

                            /** When soundsModel has less `soundGrid.columns`, alignment issue occurs because of
                              * less amount of items than columns. Add spacers of same width and height as elements
                              */
                            Repeater {
                                model: soundButtonsRepeater.count < soundGrid.columns
                                        ? soundGrid.columns - soundButtonsRepeater.count
                                        : 0
                                delegate: Item {
                                    id: spacer
                                    Layout.fillWidth: false
                                    Layout.fillHeight: false
                                    Layout.preferredWidth: soundGrid.cellWidth
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 4.5
                                }
                            }
                        }
                    }
                }
            }
        }

        // Bottom Row : Display current sound/sample/fx data
        ColumnLayout {
            id: soundDetails
            property bool displaySelectedSoundData: soundButtonGroup.checkedButton != null && soundButtonGroup.checkedButton.checked
            Layout.fillWidth: true

            QQC2.Label {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                Layout.leftMargin: Kirigami.Units.gridUnit
                Layout.rightMargin: Kirigami.Units.gridUnit
                horizontalAlignment: Qt.AlignLeft
                verticalAlignment: Qt.AlignVCenter
                elide: "ElideRight"
                font.pointSize: 16
                text: soundDetails.displaySelectedSoundData
                        ? soundButtonGroup.checkedButton.soundObj.name
                        : qsTr("Track %1 Current Sound").arg(root.selectedChannel.name)
            }

            Kirigami.Separator {
                Layout.fillWidth: true
                Layout.preferredHeight: 2
            }

            RowLayout {
                Layout.fillWidth: true
                QQC2.Label {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    horizontalAlignment: Qt.AlignRight
                    verticalAlignment: Qt.AlignVCenter
                    text: qsTr("Synth :")
                }
                Sketchpad.TrackSlotsData {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.8
                    slotData: soundDetails.displaySelectedSoundData
                                ? soundButtonGroup.checkedButton.soundObj.synthSlotsData
                                : root.selectedChannel.synthSlotsData
                    slotType: soundDetails.displaySelectedSoundData
                                ? "text"
                                : "synth"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                QQC2.Label {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    horizontalAlignment: Qt.AlignRight
                    verticalAlignment: Qt.AlignVCenter
                    text: qsTr("Samples :")
                }
                Sketchpad.TrackSlotsData {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.8
                    slotData: soundDetails.displaySelectedSoundData
                                ? soundButtonGroup.checkedButton.soundObj.sampleSlotsData
                                : root.selectedChannel.sampleSlotsData
                    slotType: soundDetails.displaySelectedSoundData
                                ? "text"
                                : "sample-trig"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                QQC2.Label {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    horizontalAlignment: Qt.AlignRight
                    verticalAlignment: Qt.AlignVCenter
                    text: qsTr("Fx :")
                }
                Sketchpad.TrackSlotsData {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.8
                    slotData: soundDetails.displaySelectedSoundData
                                ? soundButtonGroup.checkedButton.soundObj.fxSlotsData
                                : root.selectedChannel.fxSlotsData
                    slotType: soundDetails.displaySelectedSoundData
                                ? "text"
                                : "fx"
                }
            }
        }
    }
}
