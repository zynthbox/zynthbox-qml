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

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.DialogQuestion {
    id: component
    function pickSamplePickingStyle(channel) {
        _private.selectedChannel = channel;
        _private.newPickingStyle = channel.samplePickingStyle;
        _private.newTrustExternalDeviceChannels = channel.trustExternalDeviceChannels;
        component.open();
    }
    onAccepted: {
        if (_private.selectedChannel.samplePickingStyle !== _private.newPickingStyle) {
            _private.selectedChannel.samplePickingStyle = _private.newPickingStyle;
        }
        if (_private.selectedChannel.trustExternalDeviceChannels !== _private.newTrustExternalDeviceChannels) {
            _private.selectedChannel.trustExternalDeviceChannels = _private.newTrustExternalDeviceChannels
        }
    }
    height: Kirigami.Units.gridUnit * 25
    width: Kirigami.Units.gridUnit * 35
    rejectText: qsTr("Cancel")
    acceptText: qsTr("OK")
    title: qsTr("Choose Sample Picking Style For Track %1").arg(_private.selectedChannel ? _private.selectedChannel.name : "")

    additionalButtons: _private.newPickingStyle === "same" ? [styleButtonSame, styleButtonFirst, styleButtonAll, sameButtonUntrust, sameButtonTrust] :  [styleButtonSame, styleButtonFirst, styleButtonAll]
    property var cuiaCallback: function(cuia) {
        var returnValue = true;
        switch (cuia) {
            case "KNOB0_UP":
                if (_private.newPickingStyle === "same") {
                    _private.newPickingStyle = "first";
                } else if (_private.newPickingStyle === "first") {
                    _private.newPickingStyle = "all";
                }
                break;
            case "KNOB0_DOWN":
                if (_private.newPickingStyle === "all") {
                    _private.newPickingStyle = "first";
                } else if (_private.newPickingStyle === "first") {
                    _private.newPickingStyle = "same";
                }
                break;
            case "KNOB3_UP":
            case "NAVIGATE_RIGHT":
                component.selectNextButton();
                break;
            case "KNOB3_DOWN":
            case "NAVIGATE_LEFT":
                component.selectPreviousButton();
                break;
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
                component.reject();
                break;
            case "SWITCH_SELECT_SHORT":
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
            property string newPickingStyle
            property bool newTrustExternalDeviceChannels
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 4
            wrapMode: Text.Wrap
            text: qsTr("When using samples for musical playback, the specific samples that get picked for playing by SamplerSynth when a note arrives from playing a Clip's pattern steps or from a midi controller are selected in one of a few possible ways.")
        }
        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            QQC2.Button {
                id: styleButtonSame
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("Same Only")
                checked: _private.newPickingStyle === "same"
                MouseArea {
                    anchors.fill: parent
                    onClicked: parent.clicked();
                }
                onClicked: {
                    _private.newPickingStyle = "same";
                }
                Zynthian.DialogQuestionButtonFocusHighlight { selectedButton: component.selectedButton }
            }
            QQC2.Button {
                id: styleButtonFirst
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("First Match")
                checked: _private.newPickingStyle === "first"
                MouseArea {
                    anchors.fill: parent
                    onClicked: parent.clicked();
                }
                onClicked: {
                    _private.newPickingStyle = "first";
                }
                Zynthian.DialogQuestionButtonFocusHighlight { selectedButton: component.selectedButton }
            }
            QQC2.Button {
                id: styleButtonAll
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("All Matches")
                checked: _private.newPickingStyle === "all"
                MouseArea {
                    anchors.fill: parent
                    onClicked: parent.clicked();
                }
                onClicked: {
                    _private.newPickingStyle = "all";
                }
                Zynthian.DialogQuestionButtonFocusHighlight { selectedButton: component.selectedButton }
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 12
            wrapMode: Text.Wrap
            text: {
                if (_private.newPickingStyle === "same") {
                    return qsTr("This style only considers the sample in the same slot as the clip being played (for example, Clip b will look in slot 3, and Clip a will look in slot 1). If no sample is set in that slot, no sound will be made.\nThis is particularly useful for separating out things like a drum beat into its individual stems, so you have for example a snare part in one slot, and hihat part in another. It does reduce the amount of Clips available to each of those sounds, and removes the ability to handle the samples using MPE, but it allows for per-step tuning of the instruments (set Key Split to the default Off to achieve this).\nTo individual slots using an external device, use the Input MIDI Channels Match Slot, otherwise all input from external MIDI controllers is sent to the current clip's slot");
                } else if (_private.newPickingStyle === "first") {
                    return qsTr("This style will look at all the sample slots in order, and the first sample which has a key zone setup matching the incoming note will be selected.\nThis is particularly useful for wide-split key zone setups, where you have a sample set in each slot, but have them split across areas of the note range, but still allowing chromatic playback within that two octave split for all five slots.");
                } else if (_private.newPickingStyle === "all") {
                    return qsTr("This style will look at all sample slots, and all samples which match the incoming note will be selected.\nThis is particularly useful if you simply want to layer multiple samples when you play notes, or if you are doing more intricate sound design work. This goes well with either setting Key Split to the default Off, or manually setting up your key zones.");
                }
                return "";
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            opacity: _private.newPickingStyle === "same" ? 1 : 0
            QQC2.Button {
                id: sameButtonUntrust
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("All Input to Current Clip's Slot")
                checked: _private.newTrustExternalDeviceChannels === false
                MouseArea {
                    anchors.fill: parent
                    onClicked: parent.clicked();
                }
                onClicked: {
                    _private.newTrustExternalDeviceChannels = false;
                }
                Zynthian.DialogQuestionButtonFocusHighlight { selectedButton: component.selectedButton }
            }
            QQC2.Button {
                id: sameButtonTrust
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("Input MIDI Channels Match Slot")
                checked: _private.newTrustExternalDeviceChannels === true
                MouseArea {
                    anchors.fill: parent
                    onClicked: parent.clicked();
                }
                onClicked: {
                    _private.newTrustExternalDeviceChannels = true;
                }
                Zynthian.DialogQuestionButtonFocusHighlight { selectedButton: component.selectedButton }
            }
        }
    }
}
