/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian audio bounce popup control

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
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

QQC2.Popup {
    id: root
    function bounce(track) {
        _private.selectedTrack = track;
        open();
    }

    modal: true
    focus: true
    parent: QQC2.Overlay.overlay
    y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
    x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
    closePolicy: _private.bounceProgress === -1 ? (QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside) : QQC2.Popup.NoAutoClose

    ColumnLayout {
        anchors.fill: parent
        implicitWidth: Kirigami.Units.gridUnit * 30
        Kirigami.Heading {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "Bounce To Loop"
 
            QtObject {
                id: _private
                property QtObject selectedTrack
                property double bounceProgress: -1
                function performBounce() {
                    _private.bounceProgress = 0.0;
                    // Now everything is locked down, set up the sequence to do stuff for us (and store a few things so we can revert it as well)
                    // If there's currently a pattern set to be solo, let's remember that
                    // Now, set the pattern we're wanting to record as solo
                    // Startrecordingandplaything!
                    testTimerThing.start();
                }
                property QtObject testTimerThing: Timer {
                    repeat: true;
                    running: false;
                    interval: 50;
                    onTriggered: {
                        if (_private.bounceProgress < 1) {
                            // set progress based on what the thing is actually doing
                            _private.bounceProgress = _private.bounceProgress + 0.01;
                        } else {
                            stop();
                            _private.bounceProgress = -1;
                            // Reset solo to whatever it was before we started working
                            // Set the bounced wave as loop sample
                            // Set track mode to loop
                            root.close();
                        }
                    }
                }
                property bool includeLeadin: false
                property bool includeLeadinInLoop: false
                property bool includeFadeout: false
                property bool includeFadeoutInLoop: false
            }
            Connections {
                target: root
                onOpenedChanged: {
                    if (!root.opened) {
                        _private.includeLeadin = false;
                        _private.includeLeadinInLoop = false;
                        _private.includeFadeout = false;
                        _private.includeFadeoutInLoop = false;
                    }
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: 1
            Layout.maximumHeight: 1
            color: Kirigami.Theme.textColor
            opacity: 0.5
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 30
            wrapMode: Text.Wrap
            text: "Bounce the audio from the pattern in " + (_private.selectedTrack ? _private.selectedTrack.name : "") + " to a wave file, assign that recording as the track's loop sample, and set the track to loop mode.";
        }
        QQC2.CheckBox {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "Include lead-in"
            checked: _private.includeLeadin
            onClicked: { _private.includeLeadin = !_private.includeLeadin; }
        }
        QQC2.CheckBox {
            Layout.fillWidth: true
            Layout.fillHeight: true
            enabled: _private.includeLeadin
            opacity: enabled ? 1 : 0.5
            text: "Include lead-in in loop"
            checked: _private.includeLeadinInLoop
            onClicked: { _private.includeLeadinInLoop = !_private.includeLeadinInLoop; }
        }
        QQC2.CheckBox {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "Include fade-out"
            checked: _private.includeFadeout
            onClicked: { _private.includeFadeout = !_private.includeFadeout; }
        }
        QQC2.CheckBox {
            Layout.fillWidth: true
            Layout.fillHeight: true
            enabled: _private.includeFadeout
            opacity: enabled ? 1 : 0.5
            text: "Include fade-out in loop"
            checked: _private.includeFadeoutInLoop
            onClicked: { _private.includeFadeoutInLoop = !_private.includeFadeoutInLoop; }
        }
        QQC2.ProgressBar {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 30
            opacity: _private.bounceProgress > -1 ? 1 : 0.3
            value: _private.bounceProgress
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: 1
            Layout.maximumHeight: 1
            color: Kirigami.Theme.textColor
            opacity: 0.5
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                text: "Bounce"
                enabled: _private.bounceProgress === -1
                onClicked: {
                    _private.performBounce();
                }
            }
            QQC2.Button {
                Layout.fillWidth: true;
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                text: "Close"
                enabled: _private.bounceProgress === -1
                onClicked: {
                    root.close();
                }
            }
        }
    }
}
