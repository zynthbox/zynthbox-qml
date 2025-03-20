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

import QtQuick 2.15
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import '../../Zynthian' 1.0 as Zynthian
import '../Sketchpad' as Sketchpad
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.ScreenPage {
    id: root

    property QtObject selectedChannel: applicationWindow().selectedChannel
    /**
      * This signal will be emitted when some other page wants to
      * open the sound saving dialog
      */
    signal showSaveSoundDialog()

    states: [
        /**
         * This mode will be used to display snd files
         * When state is set to displayMode, display the snd files grid
         * and clicking on category button will switch to that category
         **/
        State {
            name: "displayMode"
        },
        /**
         * This mode will be used to allow picking a category when saving a snd file
         * When state is set to saveMode, display a help text in place of snd files grid
         * and clicking on category button will save the snd file to that category
         * Irrevelant contextualActions should get disabled and "Save" button should
         * allow cancelling when category is yet to be picked
         **/
        State {
            name: "saveMode"
        },
        /**
         * This mode will be used to allow updating a category of selected snd file
         * When state is set to updateCategoryMode, display a help text in place of snd files grid
         * and clicking on category button will update the selected snd file's category to that category
         * Irrevelant contextualActions should get disabled and "Move" button should
         * allow cancelling when category is yet to be picked
         **/
        State {
            name: "updateCategoryMode"
        }
    ]
    state: "displayMode"
    title: qsTr("Sound Categories")
    screenId: "sound_categories"
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8
    onShowSaveSoundDialog: {
        saveSoundDialog.open()
    }
    contextualActions: [
        Kirigami.Action {
            text: root.state !== "updateCategoryMode"
                    ? qsTr("Change Category")
                    : qsTr("Cancel")
            enabled: (root.state === "displayMode" && soundButtonGroup.checkedButton != null && soundButtonGroup.checkedButton.checked) ||
                     root.state === "updateCategoryMode"
            onTriggered: {
                if (root.state == "displayMode") {
                    root.state = "updateCategoryMode"
                } else {
                    root.state = "displayMode"
                }
            }
        },
        Kirigami.Action {
            // True when action acts as save button, false when acts as load button
            property bool isSaveBtn: soundButtonGroup.checkedButton == null || !soundButtonGroup.checkedButton.checked
            enabled: root.state === "displayMode" || root.state === "saveMode"
            text: isSaveBtn
                    ? root.state === "saveMode"
                        ? qsTr("Cancel")
                        : qsTr("Save")
                    : qsTr("Load")
            onTriggered: {
                if (isSaveBtn) {
                    if (root.state === "saveMode") {
                        // Reset to displayMode when cancel button is pressed
                        root.state = "displayMode"
                    } else {
                        saveSoundDialog.open()
                    }
                } else {
                    zynqtgui.sound_categories.loadSound(soundButtonGroup.checkedButton.soundObj)
                }
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
                Zynthbox.SndLibrary.setOriginFilter(soundTypeComboBox.model[soundTypeComboBox.currentIndex])

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
        onAccepted: {
            root.state = "saveMode"
        }
        onOpened: {
            saveSoundDialog.fileName = zynqtgui.sound_categories.suggestedSoundFileName()
        }
        Timer {
            id: fileCheckTimer
            interval: 50
            onTriggered: {
                saveSoundDialog.conflict = zynqtgui.sound_categories.checkIfSoundFileExists(saveSoundDialog.fileName);
            }
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
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
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
                    spacing: content.spacing
                    Repeater {
                        id: categoryButtonsRepeater
                        model: ["*", "4", "5", "3", "6", "2", "1", "99"]
                        delegate: CategoryButton {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            category: modelData
                            checkable: root.state === "displayMode"
                            checked: modelData == "*" // `All` button is checked by default
                            highlighted: root.state === "displayMode" && checked
                            // `All` button should be disabled when in save mode or updateCategoryMode
                            // Also selected snd files current category button should be disabled when in updateCategoryMode
                            enabled: root.state === "displayMode" ||
                                     (root.state === "saveMode" && modelData != "*") ||
                                     (root.state === "updateCategoryMode" && modelData != "*" && soundButtonGroup.checkedButton != null && soundButtonGroup.checkedButton.soundObj.category != modelData)
                            onCheckedChanged: {
                                if (root.state === "displayMode" && checked) {
                                    // If scrollview is not at top and category is set, UI seems to hang when sort calls are made
                                    // Hence, scroll to top before swtiching category.
                                    soundsGrid.contentY = 0;
                                    Qt.callLater(Zynthbox.SndLibrary.setCategoryFilter, category);
                                }
                            }
                            onClicked: {
                                if (root.state === "saveMode") {
                                    zynqtgui.sound_categories.saveSound(saveSoundDialog.fileName, modelData)
                                    // Reset to display mode after saving sound
                                    root.state = "displayMode"
                                } else if (root.state === "updateCategoryMode") {
                                    console.log(`Update category of ${soundButtonGroup.checkedButton.soundObj.name} to ${modelData}`)
                                    root.state = "displayMode"
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: soundsDisplayContainer
                Layout.fillWidth: true
                Layout.fillHeight: true

                QQC2.Label {
                    anchors.centerIn: parent
                    visible: root.state === "saveMode"
                    text: qsTr("Pick a category to save snd file to")
                }

                QQC2.Label {
                    anchors.centerIn: parent
                    visible: root.state === "updateCategoryMode"
                    text: qsTr("Pick a category to update selected snd file's category")
                }

                ColumnLayout {
                    anchors.fill: parent
                    visible: root.state === "displayMode"

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
                                Zynthbox.SndLibrary.setOriginFilter(model[index])
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
                            onClicked: {
                                zynqtgui.sound_categories.generateStatFiles()
                            }

                            Kirigami.Icon {
                                anchors.fill: parent
                                anchors.margins: 4
                                source: Qt.resolvedUrl("../../../img/refresh.svg")
                                color: "#ffffffff"
                            }
                        }
                    }

                    QQC2.ButtonGroup {
                        id: soundButtonGroup
                    }

                    GridView {
                        id: soundsGrid
                        property int columns: 5
                        property real spacing: Kirigami.Units.largeSpacing

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        cellWidth: (width - spacing * (columns - 1)) / columns
                        cellHeight: Kirigami.Units.gridUnit * 4.5
                        clip: true
                        model: Zynthbox.SndLibrary.model
                        reuseItems: true
                        QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                            width: Kirigami.Units.gridUnit
                            height: Kirigami.Units.gridUnit * 3
                            anchors {
                                right: parent.right
                                rightMargin: width
                            }
                            policy: QQC2.ScrollBar.AlwaysOn
                        }
                        delegate: Item {
                            width: soundsGrid.cellWidth
                            height: soundsGrid.cellHeight

                            QQC2.Button {
                                id: soundButton
                                property QtObject soundObj: model.sound
                                property bool wasChecked
                                anchors.fill: parent
                                anchors.margins: soundsGrid.spacing
                                QQC2.ButtonGroup.group: soundButtonGroup
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
                                    text: model.name
                                    wrapMode: QQC2.Label.WrapAtWordBoundaryOrAnywhere
                                    horizontalAlignment: QQC2.Label.AlignHCenter
                                    verticalAlignment: QQC2.Label.AlignVCenter
                                }

                                QQC2.Label {
                                    anchors {
                                        right: parent.right
                                        bottom: parent.bottom
                                        margins: Kirigami.Units.smallSpacing
                                    }
                                    text: zynqtgui.sound_categories.getCategoryNameFromKey(soundButton.soundObj.category)
                                    font.pointSize: 8
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
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2
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
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2
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
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2
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
