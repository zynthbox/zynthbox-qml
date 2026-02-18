/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Sketch Unbouncer, for unbouncing sketches (write the sketch source into sound setup and pattern)

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

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami


import io.zynthbox.ui 1.0 as ZUI

import io.zynthbox.components 1.0 as Zynthbox

ZUI.DialogQuestion {
    id: component
    function pickTrackStyle(channel) {
        _private.selectedChannel = channel;
        _private.newTrackStyle = channel.trackStyle;
        component.open();
    }
    onAccepted: {
        if (_private.selectedChannel.trackStyle !== _private.newTrackStyle) {
            _private.selectedChannel.trackStyle = _private.newTrackStyle;
        }
    }
    height: Kirigami.Units.gridUnit * 20
    width: Kirigami.Units.gridUnit * 35
    rejectText: qsTr("Cancel")
    acceptText: qsTr("OK")
    title: qsTr("Choose Track Style For Track %1").arg(_private.selectedChannel ? _private.selectedChannel.name : "")

    additionalButtons: [styleButtonEverything, styleButtonOneToOne, styleButtonDrums, sameButton2low3high, sameButton10Split]
    property var cuiaCallback: function(cuia) {
        var returnValue = true;
        switch (cuia) {
            case "KNOB0_UP":
                if (_private.newTrackStyle === "everything") {
                    _private.newTrackStyle = "one-to-one";
                } else if (_private.newTrackStyle === "one-to-one") {
                    _private.newTrackStyle = "drums";
                } else if (_private.newTrackStyle === "drums") {
                    _private.newTrackStyle = "2-low-3-high";
                } else if (_private.newTrackStyle === "2-low-3-high") {
                    _private.newTrackStyle = "10-split";
                }
                break;
            case "KNOB0_DOWN":
                if (_private.newTrackStyle === "10-split") {
                    _private.newTrackStyle = "2-low-3-high";
                } else if (_private.newTrackStyle === "2-low-3-high") {
                    _private.newTrackStyle = "drums";
                } else if (_private.newTrackStyle === "drums") {
                    _private.newTrackStyle = "one-to-one";
                } else if (_private.newTrackStyle === "one-to-one") {
                    _private.newTrackStyle = "everything";
                }
                break;
            case "KNOB3_UP":
            case "SWITCH_ARROW_RIGHT_RELEASED":
                component.selectNextButton();
                break;
            case "KNOB3_DOWN":
            case "SWITCH_ARROW_LEFT_RELEASED":
                component.selectPreviousButton();
                break;
            case "SWITCH_BACK_RELEASED":
                component.reject();
                break;
            case "SWITCH_KNOB3_RELEASED":
            case "SWITCH_SELECT_RELEASED":
                if (component.selectedButton.enabled) {
                    component.selectedButton.clicked();
                }
                break;
        }
        return returnValue;
    }

    contentItem: ColumnLayout {
        QtObject {
            id: _private
            property QtObject selectedChannel
            property string newTrackStyle
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 4
            wrapMode: Text.Wrap
            text: qsTr("When using samples for musical playback, the specific samples that get picked for playing when a note arrives from playing a Clip's pattern steps or from a midi controller are selected in one of a few possible ways.")
        }
        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            QQC2.Button {
                id: styleButtonEverything
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("Everything")
                checked: _private.newTrackStyle === "everything"
                MouseArea {
                    anchors.fill: parent
                    onClicked: parent.clicked();
                }
                onClicked: {
                    _private.newTrackStyle = "everything";
                }
                ZUI.DialogQuestionButtonFocusHighlight { selectedButton: component.selectedButton }
                ZUI.KnobIndicator {
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        margins: 2
                    }
                    height: parent.height * 0.5
                    width: height
                    knobId: 0
                    visible: parent.checked
                }
            }
            QQC2.Button {
                id: styleButtonOneToOne
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("5 Columns")
                checked: _private.newTrackStyle === "one-to-one"
                MouseArea {
                    anchors.fill: parent
                    onClicked: parent.clicked();
                }
                onClicked: {
                    _private.newTrackStyle = "one-to-one";
                }
                ZUI.DialogQuestionButtonFocusHighlight { selectedButton: component.selectedButton }
                ZUI.KnobIndicator {
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        margins: 2
                    }
                    height: parent.height * 0.5
                    width: height
                    knobId: 0
                    visible: parent.checked
                }
            }
            QQC2.Button {
                id: styleButtonDrums
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("Drumrack")
                checked: _private.newTrackStyle === "drums"
                MouseArea {
                    anchors.fill: parent
                    onClicked: parent.clicked();
                }
                onClicked: {
                    _private.newTrackStyle = "drums";
                }
                ZUI.DialogQuestionButtonFocusHighlight { selectedButton: component.selectedButton }
                ZUI.KnobIndicator {
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        margins: 2
                    }
                    height: parent.height * 0.5
                    width: height
                    knobId: 0
                    visible: parent.checked
                }
            }
            QQC2.Button {
                id: styleButton2low3high
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("Upper/Lower")
                checked: _private.newTrackStyle === "2-low-3-high"
                MouseArea {
                    anchors.fill: parent
                    onClicked: parent.clicked();
                }
                onClicked: {
                    _private.newTrackStyle = "2-low-3-high";
                }
                ZUI.DialogQuestionButtonFocusHighlight { selectedButton: component.selectedButton }
                ZUI.KnobIndicator {
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        margins: 2
                    }
                    height: parent.height * 0.5
                    width: height
                    knobId: 0
                    visible: parent.checked
                }
            }
            QQC2.Button {
                id: styleButton10Split
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("10 Split")
                checked: _private.newTrackStyle === "10-split"
                MouseArea {
                    anchors.fill: parent
                    onClicked: parent.clicked();
                }
                onClicked: {
                    _private.newTrackStyle = "10-split";
                }
                ZUI.DialogQuestionButtonFocusHighlight { selectedButton: component.selectedButton }
                ZUI.KnobIndicator {
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        margins: 2
                    }
                    height: parent.height * 0.5
                    width: height
                    knobId: 0
                    visible: parent.checked
                }
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 12
            wrapMode: Text.Wrap
            text: {
                if (_private.newTrackStyle === "everything") {
                    return qsTr("All slots are played by every note which arrives, as those notes arrive. No key-splitting is set up or enforced for the slots, and all clips play into all slots.");
                } else if (_private.newTrackStyle === "one-to-one") {
                    return qsTr("Clips will play notes as they arrive to the slot column which matches their number. That is, Clip A will play into the slots in the first column, and those sounds are played into the fx in that column. For external controllers, their notes are sent to the current Clip's column.");
                } else if (_private.newTrackStyle === "drums") {
                    return qsTr("Slots each take precise one note, laid out sequentially from C4 (MIDI note 60), which also will be used as the sample's root note. The note assignment is enforced when samples are first loaded into a slot, but should you wish to, you can later edit these assignments.");
                } else if (_private.newTrackStyle === "2-low-3-high") {
                    return qsTr("Slots will be assigned an even split on the keyboard, with slots in columns 1 and 2 being given the notes from B3 and down (MIDI note 59), and columns 3, 4, and 5 given the notes from C4 and up. The samples are further given root notes which create a playback overlap, so the lower split's samples are transposed up by 2 octaves (24 semitones), and the upper split down by that same amount.");
                } else if (_private.newTrackStyle === "10-split") {
                    return qsTr("Each slot is assigned an octave, and their root note is set to the centrepoint of that octave. That is, slot 1 will be given C-1 (MIDI note 0) through B-1 (note 11), and use F-1 (note 5) as its root. Slot 4, in turn, will use C2 through B2, with F2 as the root. Slot 10 gets C8 through B8, with F8 as the root, and so on and so forth. This is only enforced on first load, meaning that you can edit the keyzones later should you need to, to ensure your notes play at the appropriate pitch.");
                }
                return "";
            }
        }
    }
}
