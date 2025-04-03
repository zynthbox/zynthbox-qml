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
      * This property will store which origin is currently selected.
      * When updated, a call to SndLibrary will be made to filter the sounds by selected origin
      * Accepted values : my-sounds, community-sounds, ""(Will display both my-sounds and community-sounds)
      * Default : ""
      */
    property string selectedOrigin: ""
    /**
      * This property will store which category is currently selected.
      * When updated, a call to SndLibrary will be made to filter the sounds by selected category
      * Accepted values : Category value
      * Default : "*"(All categories)
      */
    property string selectedCategory: "*"
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
    onSelectedOriginChanged: {
        Zynthbox.SndLibrary.setOriginFilter(root.selectedOrigin)
    }
    onSelectedCategoryChanged: {
        // If scrollview is not at top and category is set, UI seems to hang when sort calls are made
        // Hence, scroll to top before swtiching category.
        soundsGrid.contentY = 0;
        Qt.callLater(Zynthbox.SndLibrary.setCategoryFilter, root.selectedCategory);
        // Uncheck checked button from previous selected category
        if (soundButtonGroup.checkedButton && soundButtonGroup.checkedButton.checked) {
            soundButtonGroup.checkedButton.checked = false
        }
    }

    contextualActions: [
        Kirigami.Action {
            text: root.state !== "updateCategoryMode"
                    ? root.selectedCategory == "100" && soundButtonGroup.checkedButton != null && soundButtonGroup.checkedButton.soundObj.category == "100"
                      ? qsTr("Remove from Best Of")
                      : qsTr("Change Category")
                    : qsTr("Cancel")
            enabled: (root.state === "displayMode" && soundButtonGroup.checkedButton != null && soundButtonGroup.checkedButton.checked) ||
                     root.state === "updateCategoryMode"
            onTriggered: {
                if (root.state == "displayMode") {
                    // If selected sound is in "Best Of", use this button to remove from "Best Of"
                    if (soundButtonGroup.checkedButton != null && soundButtonGroup.checkedButton.soundObj.category == "100") {
                        Zynthbox.SndLibrary.removeFromBestOf(soundButtonGroup.checkedButton.soundObj)
                    } else {
                        root.state = "updateCategoryMode"
                    }
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
        },
        Kirigami.Action {
            text: qsTr("Get New Sounds")
            onTriggered: zynqtgui.show_modal("sound_downloader")
        }
    ]

    cuiaCallback: function(cuia) {
        // TODO: Refactor some of the various selection logic in the views below to use currentIndex and currentItem instead of doing manual item checking...
        let result = false;
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_LONG":
            {
                switch (root.state) {
                    case "updateCategoryMode":
                        root.state = "saveMode";
                        result = true;
                        break;
                    case "saveMode":
                        root.state = "displayMode";
                        result = true;
                        break;
                    default:
                    case "displayMode":
                        break;
                }
                break;
            }
            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_LONG":
                // For now, toggle whatever's the current item as selected... (when not in updateCategoryMode)
                switch (root.state) {
                    case "updateCategoryMode":
                        break;
                    case "saveMode":
                        break;
                    default:
                    case "displayMode":
                        break;
                }
                result = true;
                break;
            case "SELECT_UP":
                // Select the next category up (when not in updateCategoryMode)
                switch (root.state) {
                    case "updateCategoryMode":
                        break;
                    case "saveMode":
                        break;
                    default:
                    case "displayMode":
                        break;
                }
                result = true;
                break;
            case "SELECT_DOWN":
                // Select the next category down (when not in updateCategoryMode)
                switch (root.state) {
                    case "updateCategoryMode":
                        break;
                    case "saveMode":
                        break;
                    default:
                    case "displayMode":
                        break;
                }
                result = true;
                break;
            case "KNOB3_UP":
                // Select the next item in the sounds list, and make it actually selected (when not in updateCategoryMode)
                switch (root.state) {
                    case "updateCategoryMode":
                        break;
                    case "saveMode":
                        break;
                    default:
                    case "displayMode":
                        break;
                }
                result = true;
                break;
            case "KNOB3_DOWN":
                // Select the previous item in the sounds, and make it actually selected (when not in updateCategoryMode)
                switch (root.state) {
                    case "updateCategoryMode":
                        break;
                    case "saveMode":
                        break;
                    default:
                    case "displayMode":
                        break;
                }
                result = true;
                break;
        }
        return result;
    }

    Connections {
        target: zynqtgui
        onCurrent_screen_idChanged: {
            // Refresh sounds model on page open
            if (zynqtgui.current_screen_id === root.screenId) {
                Zynthbox.SndLibrary.setOriginFilter(root.selectedOrigin)

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

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: spacing
                    spacing: content.spacing
                    Repeater {
                        model: ["*", "4", "5", "3", "6", "2", "1", "99"]
                        delegate: CategoryButton {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            checked: modelData == "*" // `All` button is checked by default
                            category: modelData
                            origin: root.selectedOrigin
                            highlighted: root.state === "displayMode" && root.selectedCategory === category
                            // `All` button should be disabled when in save mode or updateCategoryMode
                            // Also selected snd files current category button should be disabled when in updateCategoryMode
                            enabled: root.state === "displayMode" ||
                                     (root.state === "saveMode" && modelData != "*") ||
                                     (root.state === "updateCategoryMode" && modelData != "*" && soundButtonGroup.checkedButton != null && soundButtonGroup.checkedButton.soundObj.category != modelData)
                            onClicked: {
                                if (root.state === "saveMode") {
                                    zynqtgui.sound_categories.saveSound(saveSoundDialog.fileName, modelData)
                                    // Reset to display mode after saving sound
                                    root.state = "displayMode"
                                } else if (root.state === "updateCategoryMode") {
                                    Zynthbox.SndLibrary.updateSndFileCategory(soundButtonGroup.checkedButton.soundObj, modelData)
                                    root.state = "displayMode"
                                } else if (root.state === "displayMode" && root.selectedCategory != category) {
                                    root.selectedCategory = category
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    id: originTabsContainer
                    Layout.fillHeight: false
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                    Layout.alignment: Qt.AlignCenter
                    enabled: root.state === "displayMode"

                    QQC2.ButtonGroup {
                        id: originTabsButtonGroup
                    }

                    QQC2.Button {
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        checked: root.selectedOrigin == ""
                        checkable: true
                        QQC2.ButtonGroup.group: originTabsButtonGroup
                        text: qsTr("All")
                        onCheckedChanged: {
                            if (checked) {
                                root.selectedOrigin = ""
                            }
                        }
                    }
                    QQC2.Button {
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        checked: root.selectedOrigin == "my-sounds"
                        checkable: true
                        QQC2.ButtonGroup.group: originTabsButtonGroup
                        text: qsTr("My Sounds")
                        onCheckedChanged: {
                            if (checked) {
                                root.selectedOrigin = "my-sounds"
                            }
                        }
                    }
                    QQC2.Button {
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        checked: root.selectedOrigin == "community-sounds"
                        checkable: true
                        QQC2.ButtonGroup.group: originTabsButtonGroup
                        text: qsTr("Community Sounds")
                        onCheckedChanged: {
                            if (checked) {
                                root.selectedOrigin = "community-sounds"
                            }
                        }
                    }

                    QQC2.Button {
                        Layout.fillHeight: true
                        Layout.preferredWidth: height
                        onClicked: {
                            zynqtgui.sound_categories.processSndFiles(["/zynthian/zynthian-my-data/sounds/" + root.selectedOrigin])
                        }

                        Kirigami.Icon {
                            anchors.fill: parent
                            anchors.margins: 4
                            source: Qt.resolvedUrl("../../../img/refresh.svg")
                            color: "#ffffffff"
                        }
                    }
                }

                RowLayout {
                    Layout.preferredWidth: originTabsContainer.width
                    Layout.minimumWidth: originTabsContainer.width
                    Layout.maximumWidth: originTabsContainer.width
                    Layout.fillHeight: false
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                    Layout.alignment: Qt.AlignCenter

                    CategoryButton {
                        property string checkedCategoryBefore

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        category: "100"
                        origin: root.selectedOrigin
                        checkable: root.state === "displayMode"
                        highlighted: root.state === "displayMode" && root.selectedCategory === category
                        // Also selected snd files current category button should be disabled when in updateCategoryMode
                        enabled: root.state === "displayMode" ||
                                 root.state !== "saveMode" || // When in save mode disable saving to best of category
                                 (root.state === "updateCategoryMode" && soundButtonGroup.checkedButton != null && soundButtonGroup.checkedButton.soundObj.category != category)
                        onPressed: {
                            // Set the category which was selected before clicking on "Best Of" button.
                            if (root.selectedCategory != "100") {
                                checkedCategoryBefore = root.selectedCategory
                            }
                        }
                        onClicked: {
                            if (root.state === "updateCategoryMode") {
                                Zynthbox.SndLibrary.addToBestOf(soundButtonGroup.checkedButton.soundObj)
                                root.state = "displayMode"
                            } else if (root.state === "displayMode" && root.selectedCategory != category) {
                                root.selectedCategory = category
                            } else if (root.state === "displayMode" && root.selectedCategory == category) {
                                root.selectedCategory = checkedCategoryBefore
                            }
                        }
                    }
                }
                QQC2.ButtonGroup {
                    id: soundButtonGroup
                }

                Item {
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

                    GridView {
                        id: soundsGrid
                        property int columns: 5
                        property real spacing: Kirigami.Units.largeSpacing

                        anchors.fill: parent
                        visible: root.state === "displayMode"
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
                                    anchors {
                                        left: parent.left
                                        top: parent.top
                                        right: parent.right
                                        margins: Kirigami.Units.smallSpacing
                                    }
                                    text: soundButton.soundObj.origin.split("-")[0]
                                    horizontalAlignment: QQC2.Label.AlignHCenter
                                    font.pointSize: 8
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
