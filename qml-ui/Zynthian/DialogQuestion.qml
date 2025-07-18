/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Dialog component for asking binary (yes/no) questions in a globally consistent manner

Copyright (C) 2023 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.Dialog {
    id: component

    /**
     * The body of the dialog (shown in a Qt Quick Components Label)
     */
    property string text
    /**
     * The string used for the accept button
     * Set this to "" to hide the button
     */
    property string acceptText: qsTr("Yes")
    /**
     * Whether or not the accept button is enabled
     */
    property alias acceptEnabled: acceptButton.enabled
    /**
     * The string used for the reject button
     * Set this to "" to hide the button
     */
    property string rejectText: qsTr("No")
    /**
     * Whether or not the reject button is enabled
     * @note You probably don't want to actually disable this, but the property is here for symmetry
     */
    property alias rejectEnabled: rejectButton.enabled

    /**
     * Whether or not there is a text input field shown above the buttons
     */
    property alias textInputVisible: textInput.visible
    /**
     * The text in the text input field shown above the buttons
     */
    property alias inputText: textInput.text
    /**
     * Whether a button for automatically inputting a semi-random combination of an adjective and a noun
     */
    property alias adjectiveNounButtonVisible: adjectiveNounButton.visible

    property alias textHorizontalAlignment: contentText.horizontalAlignment
    property alias textVerticalAlignment: contentText.verticalAlignment

    x: Math.round(parent.width/2 - width/2)
    y: Math.round(parent.height/2 - height/2)
    width: Kirigami.Units.gridUnit * 20
    height: inputRow.visible ? Kirigami.Units.gridUnit * 13 : Kirigami.Units.gridUnit * 10
    parent: QQC2.Overlay.overlay

    property var additionalButtons: []
    readonly property alias selectedButton: _private.selectedButton
    onAdditionalButtonsChanged: _private.updateAllButtons();
    Component.onCompleted: _private.updateAllButtons();
    function selectNextButton() {
        let index = _private.allButtons.indexOf(_private.selectedButton);
        index = Math.min(index + 1, _private.allButtons.length - 1);
        _private.selectedButton = _private.allButtons[index];
    }
    function selectPreviousButton() {
        let index = _private.allButtons.indexOf(_private.selectedButton);
        index = Math.max(index - 1, 0);
        _private.selectedButton = _private.allButtons[index];
    }
    property var cuiaCallback: function(cuia) {
        var result = component.opened;
        switch (cuia) {
            case "KNOB3_DOWN":
            case "NAVIGATE_LEFT":
                component.selectPreviousButton();
                result = true;
                break;
            case "KNOB3_UP":
            case "NAVIGATE_RIGHT":
                component.selectNextButton();
                result = true;
                break;
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
                component.reject();
                result = true;
                break;
            case "SWITCH_SELECT_SHORT":
                if (component.selectedButton.enabled) {
                    component.selectedButton.clicked();
                }
                result = true;
                break;
        }
        return result;
    }

    header: ColumnLayout {
        visible: component.title != null && component.title.length > 0
        spacing: 0
        Kirigami.Heading {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            level: 2
            text: component.title
            QtObject {
                id: _private
                property var selectedButton: rejectButton
                property var allButtons: []
                readonly property var standardButtons: [rejectButton, acceptButton]
                function updateAllButtons() {
                    allButtons = standardButtons.concat(component.additionalButtons);
                }
            }
        }
        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
        }
    }
    contentItem: ColumnLayout {
        spacing: 0
        QQC2.Label {
            id: contentText
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 10
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: component.text
        }
        RowLayout {
            id: inputRow
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            QQC2.TextField {
                id: textInput
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: false
            }
            PlayGridButton {
                id: adjectiveNounButton
                Layout.fillHeight: true
                Layout.fillWidth: false
                Layout.minimumWidth: height
                Layout.maximumWidth: height
                visible: false
                icon.name: "roll"
                flat: true
                onClicked: {
                    textInput.text = Zynthbox.AdjectiveNoun.adjectiveNoun();
                }
            }
        }
    }
    footer: RowLayout {
        PlayGridButton {
            id: rejectButton
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            text: component.rejectText
            visible: text !== ""
            invertBorderColor: true
            onClicked: {
                component.reject()
            }
            DialogQuestionButtonFocusHighlight { selectedButton: _private.selectedButton }
        }
        PlayGridButton {
            id: acceptButton
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            text: component.acceptText
            visible: text !== ""
            invertBorderColor: true
            onClicked: {
                component.accept()
            }
            DialogQuestionButtonFocusHighlight { selectedButton: _private.selectedButton }
        }
    }
}

