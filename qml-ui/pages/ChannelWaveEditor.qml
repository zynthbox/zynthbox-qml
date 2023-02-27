/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Channel Wave Editor

Copyright (C) 2022 Dan Leinir Turthra Jensen <admin@leinir.dk>

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

import libzl 1.0 as ZL
import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

Zynthian.ScreenPage {
    id: component
    screenId: "channel_wave_editor"
    title: qsTr("Channel Wave Editor")

    property var cuiaCallback: function(cuia) {
        var returnValue = false;
        switch (cuia) {
            case "NAVIGATE_LEFT":
            case "SELECT_DOWN":
                _private.goLeft();
                returnValue = true;
                break;

            case "NAVIGATE_RIGHT":
            case "SELECT_UP":
                _private.goRight();
                returnValue = true;
                break;
        }
        return returnValue;
    }
    Connections {
        target: zynthian.channel_wave_editor
        onBigKnobValueChanged: {
            if (zynthian.channel_wave_editor.bigKnobValue < 0) {
                for (var i = zynthian.channel_wave_editor.bigKnobValue; i < 0; ++i) {
                    _private.goLeft();
                }
            } else if (zynthian.channel_wave_editor.bigKnobValue > 0) {
                for (var i = zynthian.channel_wave_editor.bigKnobValue; i > 0; --i) {
                    _private.goRight();
                }
            } // and no reason to do anything with 0, that's just the knob resetting itself after sending the delta out
        }
        onKnob1ValueChanged: {
            if (zynthian.channel_wave_editor.knob1Value < 0) {
                for (var i = zynthian.channel_wave_editor.knob1Value; i < 0; ++i) {
                    _private.knob1Down();
                }
            } else if (zynthian.channel_wave_editor.knob1Value > 0) {
                for (var i = zynthian.channel_wave_editor.knob1Value; i > 0; --i) {
                    _private.knob1Up();
                }
            } // and no reason to do anything with 0, that's just the knob resetting itself after sending the delta out
        }
        onKnob2ValueChanged: {
            if (zynthian.channel_wave_editor.knob2Value < 0) {
                for (var i = zynthian.channel_wave_editor.knob2Value; i < 0; ++i) {
                    _private.knob2Down();
                }
            } else if (zynthian.channel_wave_editor.knob2Value > 0) {
                for (var i = zynthian.channel_wave_editor.knob2Value; i > 0; --i) {
                    _private.knob2Up();
                }
            } // and no reason to do anything with 0, that's just the knob resetting itself after sending the delta out
        }
        onKnob3ValueChanged: {
            if (zynthian.channel_wave_editor.knob3Value < 0) {
                for (var i = zynthian.channel_wave_editor.knob3Value; i < 0; ++i) {
                    _private.knob3Down();
                }
            } else if (zynthian.channel_wave_editor.knob3Value > 0) {
                for (var i = zynthian.channel_wave_editor.knob3Value; i > 0; --i) {
                    _private.knob3Up();
                }
            } // and no reason to do anything with 0, that's just the knob resetting itself after sending the delta out
        }
    }
    QtObject {
        id: _private
        function goLeft() {
        }
        function goRight() {
        }
        function knob1Up() {
        }
        function knob1Down() {
        }
        function knob2Up() {
        }
        function knob2Down() {
        }
        function knob3Up() {
        }
        function knob3Down() {
        }
    }

    contextualActions: [
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            enabled: false
        }
    ]

    QQC2.Label {
        anchors.centerIn: parent
        text: "Some things for changing when our current channel is in one of the sample based modes"
    }
}
