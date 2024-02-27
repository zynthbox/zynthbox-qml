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
        component.open();
    }
    onAccepted: {
        if (_private.selectedChannel.samplePickingStyle !== _private.newPickingStyle) {
            _private.selectedChannel.samplePickingStyle = _private.newPickingStyle;
        }
    }
    height: Kirigami.Units.gridUnit * 25
    width: Kirigami.Units.gridUnit * 35
    acceptText: qsTr("Select")
    rejectText: qsTr("Back")
    title: qsTr("Choose Sample Picking Style For Track %1").arg(_private.selectedChannel ? _private.selectedChannel.name : "")

    additionalButtons: [styleButtonSameOrFirst, styleButtonSame, styleButtonFirst, styleButtonAll]
    property var cuiaCallback: function(cuia) {
        var returnValue = true;
        switch (cuia) {
            case "KNOB0_UP":
                if (_private.newPickingStyle === "same-or-first") {
                    _private.newPickingStyle = "same";
                } else if (_private.newPickingStyle === "same") {
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
                } else if (_private.newPickingStyle === "same") {
                    _private.newPickingStyle = "same-or-first";
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
            case "SWITCH_BACK_LONG":
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

    ColumnLayout {
        anchors {
            fill: parent
            margins: Kirigami.Units.largeSpacing
        }
        QtObject {
            id: _private
            property QtObject selectedChannel
            property string newPickingStyle
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 6
            wrapMode: Text.Wrap
            text: qsTr("When in Sample mode, the samples that get picked for playing by SamplerSynth when a note arrives from playing a Clip's pattern steps are selected in one of a few possible ways. When a note arrives at SamplerSynth, it looks at what Clip it was sent from, and then based on that information picks the appropriate sample, or samples, depending on this setting.")
        }
        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 4
            QQC2.Button {
                id: styleButtonSameOrFirst
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("Same or First")
                checked: _private.newPickingStyle === "same-or-first"
                MouseArea {
                    anchors.fill: parent
                    onClicked: parent.clicked();
                }
                onClicked: {
                    _private.newPickingStyle = "same-or-first";
                }
                Zynthian.KnobIndicator {
                    anchors {
                        right: parent.left
                        rightMargin: Kirigami.Units.smallSpacing
                        verticalCenter: parent.verticalCenter
                    }
                    height: parent.height * 0.8
                    width: height
                    knobId: 0
                }
                Zynthian.DialogQuestionButtonFocusHighlight { selectedButton: component.selectedButton }
            }
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
                if (_private.newPickingStyle === "same-or-first") {
                    return qsTr("If there is a sample in the same slot as clip being played, that sample will be chosen, regardless of key zone setup (for example, Clip C will look in slot 3, and Clip a will look in slot 1). If there is no sample there, the other slots will be searched in order, and the first sample which has a key zone setup matching the incoming note will be selected. Note that this mode disallows custom key zone setups, limiting you to either off or narrow.\nThis is our default, and is an attempt at a reasonable trade-off, allowing you to simply set some sample in one slot and use that for polyphonic, chromatic playback, or set a number of samples, and use each of those for individual Clips.");
                } else if (_private.newPickingStyle === "same") {
                    return qsTr("This style only considers the sample in the same slot as the clip being played (for example, Clip b will look in slot 3, and Clip a will look in slot 1). If no sample is set in that slot, no sound will be made.\nThis is particularly useful for separating out things like a drum beat into its individual stems, so you have for example a snare part in one slot, and hihat part in another. It does reduce the amount of Clips available to each of those sounds, but it allows for per-step tuning of the instruments (set Key Split to Off to achieve this).");
                } else if (_private.newPickingStyle === "first") {
                    return qsTr("This style will look at all the sample slots in order, and the first sample which has a key zone setup matching the incoming note will be selected.\nThis is particularly useful for wide-split key zone setups, where you have a sample set in each slot, but have them split across areas of the note range, but still allowing chromatic playback within that two octave split for all five slots.");
                } else if (_private.newPickingStyle === "all") {
                    return qsTr("This style will look at all sample slots, and all samples which match the incoming note will be selected.\nThis is particularly useful if you simply want to trigger multiple samples for the same notes, or if you are doing more intricate sound design work. This goes well with either setting Key Split to off, or manually setting up your key zones.");
                }
                return "";
            }
        }
    }
}
