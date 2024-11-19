/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Settings page for Midi Controllers

Copyright (C) 2024 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
import QtQml 2.15
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import io.zynthbox.components 1.0 as Zynthbox

DialogQuestion {
    id: notePicker
    property int selectedNote: 0
    function pickNote(currentNote, callbackFunction) {
        notePicker.selectedNote = currentNote;
        notePicker.callbackFunction = callbackFunction;
        notePicker.open();
    }
    Connections {
        target: Zynthbox.MidiRouter
        enabled: notePicker.opened
        onMidiMessage: function(port, size, byte1, byte2, byte3, sketchpadTrack, fromInternal) {
            if ((port == Zynthbox.MidiRouter.HardwareInPassthroughPort || port == Zynthbox.MidiRouter.InternalControllerPassthroughPort) && size === 3) {
                if (127 < byte1 && byte1 < 160) {
                    notePicker.selectedNote = byte2;
                }
            }
        }
    }
    property var callbackFunction: null
    cuiaCallback: function(cuia) {
        var result = notePicker.opened;
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
                notePicker.reject();
                result = true;
                break;
            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
                notePicker.accept();
                result = true;
                break;
            case "KNOB3_UP":
                if (notePicker.selectedNote < 127) {
                    notePicker.selectedNote = notePicker.selectedNote + 1;
                }
                result = true;
                break;
            case "KNOB3_DOWN":
                if (notePicker.selectedNote > 0) {
                    notePicker.selectedNote = notePicker.selectedNote - 1;
                }
                result = true;
                break;
            case "KNOB0_UP":
            case "KNOB0_DOWN":
            case "KNOB1_UP":
            case "KNOB1_DOWN":
            case "KNOB2_UP":
            case "KNOB2_DOWN":
            default:
                result = true;
                break;
        }
        return result;
    }
    title: qsTr("Pick A Note")
    acceptText: qsTr("Pick %1").arg(Zynthbox.KeyScales.midiNoteName(notePicker.selectedNote))
    onAccepted: {
        if (notePicker.callbackFunction) {
            notePicker.callbackFunction(notePicker.selectedNote);
        }
    }
    rejectText: qsTr("Back")
    height: Kirigami.Units.gridUnit * 15
    width: applicationWindow().width
    contentItem: Item {
        id: pianoKeysContainer
        Rectangle {
            anchors.fill: parent
            color: "white"
        }
        RowLayout {
            anchors.fill: parent
            spacing: 0
            Repeater {
                id: pianoKeysRepeater
                model: 128
                delegate: Item {
                    id: pianoKeyDelegate
                    readonly property int midiNote: model.index
                    readonly property var sharpMidiNotes: [1, 3, 6, 8, 10]
                    readonly property bool isSharpKey: sharpMidiNotes.indexOf(model.index % 12) > -1
                    readonly property bool previousIsSharpKey: sharpMidiNotes.indexOf((model.index - 1) % 12) > -1
                    readonly property bool isSelectedNote: notePicker.selectedNote === model.index
                    readonly property bool previousIsSelectedNote: notePicker.selectedNote === (model.index - 1)
                    Layout.fillWidth: isSharpKey ? false : true
                    Layout.fillHeight: true
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            notePicker.selectedNote = pianoKeyDelegate.midiNote;
                        }
                    }
                    Rectangle {
                        visible: parent.isSharpKey === false ? pianoKeyDelegate.isSelectedNote : false
                        anchors {
                            fill: parent
                            leftMargin: 1
                        }
                        color: Kirigami.Theme.focusColor
                    }
                    Rectangle {
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            topMargin: parent.previousIsSharpKey ? (parent.height * 3 / 5) : 0
                        }
                        width: 1
                        color: "black"
                    }
                    Rectangle {
                        visible: parent.previousIsSharpKey
                        anchors {
                            top: parent.top
                            left: parent.left
                        }
                        color: pianoKeyDelegate.previousIsSelectedNote ? Kirigami.Theme.focusColor : "black"
                        width: pianoKeysContainer.width / 200
                        height: parent.height * 3 / 5
                    }
                    Rectangle {
                        visible: parent.isSharpKey
                        anchors {
                            top: parent.top
                            right: parent.right
                        }
                        color: pianoKeyDelegate.isSelectedNote ? Kirigami.Theme.focusColor : "black"
                        width: pianoKeysContainer.width / 200
                        height: parent.height * 3 / 5
                    }
                    QQC2.Label {
                        visible: model.index % 12 === 0
                        anchors {
                            fill: parent
                            leftMargin: 2
                            rightMargin: 0
                        }
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignBottom
                        text: Zynthbox.KeyScales.octaveName(Zynthbox.KeyScales.midiNoteToOctave(pianoKeyDelegate.midiNote))
                        font.pixelSize: width
                        color: "silver"
                    }
                }
            }
        }
    }
}
