/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Popup offering the user a simple way to pick a specific midi byte

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
import QtQuick.Window 2.15
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.ComboBox {
    id: component
    visible: false;
    property int byteValue: -1
    property int messageSize: 0
    // byteType can be 0 for first byte, 1 for just picking a value, 2 for cc names
    function pickByte(byteValue, byteType, callbackFunction) {
        component.byteType = byteType;
        let testValue = byteType === 0 ? byteValue : byteValue + 128;
        for (let testIndex = 0; testIndex < model.count; ++testIndex) {
            let testElement = model.get(testIndex);
            if (testElement.value === testValue) {
                component.currentIndex = testIndex;
                break;
            }
        }
        component.callbackFunction = callbackFunction;
        component.onClicked();
    }
    property var callbackFunction: null
    property int byteType: 0
    function byteValueToMessageName(theByte) {
        for (let modelIndex = 0; modelIndex < model.count; ++modelIndex) {
            let entry = model.get(modelIndex);
            if (entry.value === theByte) {
                // console.log("Found thing!", theByte, entry.byte0text);
                return entry.byte0text;
                break;
            }
        }
        // console.log("Oh no did not find thing", theByte);
        return "Unknown Byte Value: %1".arg(theByte);
    }
    function byteValueToMessageSize(theByte) {
        for (let modelIndex = 0; modelIndex < model.count; ++modelIndex) {
            let entry = model.get(modelIndex);
            if (entry.value === theByte) {
                // console.log("Found thing!", theByte, entry.messageSize);
                return entry.messageSize;
                break;
            }
        }
        // console.log("Oh no did not find thing", theByte);
        return "Unknown Byte Value: %1".arg(theByte);
    }
    function byteValueToCCName(theByte) {
        let testValue = theByte + 128;
        for (let modelIndex = 0; modelIndex < model.count; ++modelIndex) {
            let entry = model.get(modelIndex);
            if (entry.value === testValue) {
                // console.log("Found thing!", theByte, entry.ccNameText);
                return entry.ccNameText;
                break;
            }
        }
        // console.log("Oh no did not find thing", theByte);
        return "Unknown Byte Value: %1".arg(theByte);
    }
    function byteValueToCCShorthand(theByte) {
        let testValue = theByte + 128;
        for (let modelIndex = 0; modelIndex < model.count; ++modelIndex) {
            let entry = model.get(modelIndex);
            if (entry.value === testValue) {
                // console.log("Found thing!", theByte, entry.ccNameText);
                return entry.ccNameShort;
                break;
            }
        }
        // console.log("Oh no did not find thing", theByte);
        return "Unknown Byte Value: %1".arg(theByte);
    }
    model: ListModel {
        ListElement { byte0text: "Note Off - Channel 1"; byte1text: "0"; ccNameText: "Bank Select"; ccNameShort: "Bank Select"; value: 0x80; messageSize: 3 }
        ListElement { byte0text: "Note Off - Channel 2"; byte1text: "1"; ccNameText: "Modulation Wheel or Lever"; ccNameShort: "Mod Wheel"; value: 0x81; messageSize: 3 }
        ListElement { byte0text: "Note Off - Channel 3"; byte1text: "2"; ccNameText: "Breath Controller"; ccNameShort: "Breath Controller"; value: 0x82; messageSize: 3 }
        ListElement { byte0text: "Note Off - Channel 4"; byte1text: "3"; ccNameText: "Undefined (0x03)"; ccNameShort: "CC 0x03"; value: 0x83; messageSize: 3 }
        ListElement { byte0text: "Note Off - Channel 5"; byte1text: "4"; ccNameText: "Foot Controller"; ccNameShort: "Foot Controller"; value: 0x84; messageSize: 3 }
        ListElement { byte0text: "Note Off - Channel 6"; byte1text: "5"; ccNameText: "Portamento Time"; ccNameShort: "Portamento Time"; value: 0x85; messageSize: 3 }
        ListElement { byte0text: "Note Off - Channel 7"; byte1text: "6"; ccNameText: "Data Entry MSB"; ccNameShort: "Data Entry MSB"; value: 0x86; messageSize: 3 }
        ListElement { byte0text: "Note Off - Channel 8"; byte1text: "7"; ccNameText: "Channel Volume"; ccNameShort: "Channel Volume"; value: 0x87; messageSize: 3 }
        ListElement { byte0text: "Note Off - Channel 9"; byte1text: "8"; ccNameText: "Balance"; ccNameShort: "Balance"; value: 0x88; messageSize: 3 }
        ListElement { byte0text: "Note Off - Channel 10"; byte1text: "9"; ccNameText: "Undefined (0x09)"; ccNameShort: "CC 0x09"; value: 0x89; messageSize: 3 }
        ListElement { byte0text: "Note Off - Channel 11"; byte1text: "10"; ccNameText: "Pan"; ccNameShort: "Pan"; value: 0x8A; messageSize: 3 }
        ListElement { byte0text: "Note Off - Channel 12"; byte1text: "11"; ccNameText: "Expression Controller"; ccNameShort: "Expression Ctrl"; value: 0x8B; messageSize: 3 }
        ListElement { byte0text: "Note Off - Channel 13"; byte1text: "12"; ccNameText: "Effect Control 1"; ccNameShort: "Effect Ctrl 1"; value: 0x8C; messageSize: 3 }
        ListElement { byte0text: "Note Off - Channel 14"; byte1text: "13"; ccNameText: "Effect Control 2"; ccNameShort: "Effect Ctrl 2"; value: 0x8D; messageSize: 3 }
        ListElement { byte0text: "Note Off - Channel 15"; byte1text: "14"; ccNameText: "Undefined (0x0E)"; ccNameShort: "CC 0x0E"; value: 0x8E; messageSize: 3 }
        ListElement { byte0text: "Note Off - Channel 16"; byte1text: "15"; ccNameText: "Undefined (0x0F)"; ccNameShort: "CC 0x0F"; value: 0x8F; messageSize: 3 }
        ListElement { byte0text: "Note On - Channel 1"; byte1text: "16"; ccNameText: "General Purpose Controller 1"; ccNameShort: "General Purpose 1"; value: 0x90; messageSize: 3 }
        ListElement { byte0text: "Note On - Channel 2"; byte1text: "17"; ccNameText: "General Purpose Controller 2"; ccNameShort: "General Purpose 2"; value: 0x91; messageSize: 3 }
        ListElement { byte0text: "Note On - Channel 3"; byte1text: "18"; ccNameText: "General Purpose Controller 3"; ccNameShort: "General Purpose 3"; value: 0x92; messageSize: 3 }
        ListElement { byte0text: "Note On - Channel 4"; byte1text: "19"; ccNameText: "General Purpose Controller 4"; ccNameShort: "General Purpose 4"; value: 0x93; messageSize: 3 }
        ListElement { byte0text: "Note On - Channel 5"; byte1text: "20"; ccNameText: "Undefined (0x14)"; ccNameShort: "CC 0x14"; value: 0x94; messageSize: 3 }
        ListElement { byte0text: "Note On - Channel 6"; byte1text: "21"; ccNameText: "Undefined (0x15)"; ccNameShort: "CC 0x15"; value: 0x95; messageSize: 3 }
        ListElement { byte0text: "Note On - Channel 7"; byte1text: "22"; ccNameText: "Undefined (0x16)"; ccNameShort: "CC 0x16"; value: 0x96; messageSize: 3 }
        ListElement { byte0text: "Note On - Channel 8"; byte1text: "23"; ccNameText: "Undefined (0x17)"; ccNameShort: "CC 0x17"; value: 0x97; messageSize: 3 }
        ListElement { byte0text: "Note On - Channel 9"; byte1text: "24"; ccNameText: "Undefined (0x18)"; ccNameShort: "CC 0x18"; value: 0x98; messageSize: 3 }
        ListElement { byte0text: "Note On - Channel 10"; byte1text: "25"; ccNameText: "Undefined (0x19)"; ccNameShort: "CC 0x19"; value: 0x99; messageSize: 3 }
        ListElement { byte0text: "Note On - Channel 11"; byte1text: "26"; ccNameText: "Undefined (0x1A)"; ccNameShort: "CC 0x1A"; value: 0x9A; messageSize: 3 }
        ListElement { byte0text: "Note On - Channel 12"; byte1text: "27"; ccNameText: "Undefined (0x1B)"; ccNameShort: "CC 0x1B"; value: 0x9B; messageSize: 3 }
        ListElement { byte0text: "Note On - Channel 13"; byte1text: "28"; ccNameText: "Undefined (0x1C)"; ccNameShort: "CC 0x1C"; value: 0x9C; messageSize: 3 }
        ListElement { byte0text: "Note On - Channel 14"; byte1text: "29"; ccNameText: "Undefined (0x1D)"; ccNameShort: "CC 0x1D"; value: 0x9D; messageSize: 3 }
        ListElement { byte0text: "Note On - Channel 15"; byte1text: "30"; ccNameText: "Undefined (0x1E)"; ccNameShort: "CC 0x1E"; value: 0x9E; messageSize: 3 }
        ListElement { byte0text: "Note On - Channel 16"; byte1text: "31"; ccNameText: "Undefined (0x1F)"; ccNameShort: "CC Ox1F"; value: 0x9F; messageSize: 3 }
        ListElement { byte0text: "Polyphonic Aftertouch - Channel 1"; byte1text: "32"; ccNameText: "LSB for Control 0 (Bank Select)"; ccNameShort: "LSB for Bank Sel"; value: 0xA0; messageSize: 3 }
        ListElement { byte0text: "Polyphonic Aftertouch - Channel 2"; byte1text: "33"; ccNameText: "LSB for Control 1 (Modulation Wheel or Lever)"; ccNameShort: "LSB for Mod"; value: 0xA1; messageSize: 3 }
        ListElement { byte0text: "Polyphonic Aftertouch - Channel 3"; byte1text: "34"; ccNameText: "LSB for Control 2 (Breath Controller)"; ccNameShort: "LSB for Breath"; value: 0xA2; messageSize: 3 }
        ListElement { byte0text: "Polyphonic Aftertouch - Channel 4"; byte1text: "35"; ccNameText: "LSB for Control 3 (Undefined)"; ccNameShort: "LSB for CC 0x03"; value: 0xA3; messageSize: 3 }
        ListElement { byte0text: "Polyphonic Aftertouch - Channel 5"; byte1text: "36"; ccNameText: "LSB for Control 4 (Foot Controller)"; ccNameShort: "LSB for Foot"; value: 0xA4; messageSize: 3 }
        ListElement { byte0text: "Polyphonic Aftertouch - Channel 6"; byte1text: "37"; ccNameText: "LSB for Control 5 (Portamento Time)"; ccNameShort: "LSB for Port Time"; value: 0xA5; messageSize: 3 }
        ListElement { byte0text: "Polyphonic Aftertouch - Channel 7"; byte1text: "38"; ccNameText: "LSB for Control 6 (Data Entry)"; ccNameShort: "LSB for Data Entry"; value: 0xA6; messageSize: 3 }
        ListElement { byte0text: "Polyphonic Aftertouch - Channel 8"; byte1text: "39"; ccNameText: "LSB for Control 7 (Channel Volume)"; ccNameShort: "LSB for Chan Vol"; value: 0xA7; messageSize: 3 }
        ListElement { byte0text: "Polyphonic Aftertouch - Channel 9"; byte1text: "40"; ccNameText: "LSB for Control 8 (Balance)"; ccNameShort: "LSB for Balance"; value: 0xA8; messageSize: 3 }
        ListElement { byte0text: "Polyphonic Aftertouch - Channel 10"; byte1text: "41"; ccNameText: "LSB for Control 9 (Undefined)"; ccNameShort: "LSB for CC 0x09"; value: 0xA9; messageSize: 3 }
        ListElement { byte0text: "Polyphonic Aftertouch - Channel 11"; byte1text: "42"; ccNameText: "LSB for Control 10 (Pan)"; ccNameShort: "LSB for Pan"; value: 0xAA; messageSize: 3 }
        ListElement { byte0text: "Polyphonic Aftertouch - Channel 12"; byte1text: "43"; ccNameText: "LSB for Control 11 (Expression Controller)"; ccNameShort: "LSB for Expr Ctrl"; value: 0xAB; messageSize: 3 }
        ListElement { byte0text: "Polyphonic Aftertouch - Channel 13"; byte1text: "44"; ccNameText: "LSB for Control 12 (Effect control 1)"; ccNameShort: "LSB for FX Ctrl 1"; value: 0xAC; messageSize: 3 }
        ListElement { byte0text: "Polyphonic Aftertouch - Channel 14"; byte1text: "45"; ccNameText: "LSB for Control 13 (Effect control 2)"; ccNameShort: "LSB for FX Ctrl 2"; value: 0xAD; messageSize: 3 }
        ListElement { byte0text: "Polyphonic Aftertouch - Channel 15"; byte1text: "46"; ccNameText: "LSB for Control 14 (Undefined)"; ccNameShort: "LSB for CC 0x0E"; value: 0xAE; messageSize: 3 }
        ListElement { byte0text: "Polyphonic Aftertouch - Channel 16"; byte1text: "47"; ccNameText: "LSB for Control 15 (Undefined)"; ccNameShort: "LSB for CC 0x0F"; value: 0xAF; messageSize: 3 }
        ListElement { byte0text: "Control/Mode Change - Channel 1"; byte1text: "48"; ccNameText: "LSB for Control 16 (General Purpose Controller 1)"; ccNameShort: "LSB for Gen Purp 1"; value: 0xB0; messageSize: 3 }
        ListElement { byte0text: "Control/Mode Change - Channel 2"; byte1text: "49"; ccNameText: "LSB for Control 17 (General Purpose Controller 2)"; ccNameShort: "LSB for Gen Purp 2"; value: 0xB1; messageSize: 3 }
        ListElement { byte0text: "Control/Mode Change - Channel 3"; byte1text: "50"; ccNameText: "LSB for Control 18 (General Purpose Controller 3)"; ccNameShort: "LSB for Gen Purp 3"; value: 0xB2; messageSize: 3 }
        ListElement { byte0text: "Control/Mode Change - Channel 4"; byte1text: "51"; ccNameText: "LSB for Control 19 (General Purpose Controller 4)"; ccNameShort: "LSB for Gen Purp 4"; value: 0xB3; messageSize: 3 }
        ListElement { byte0text: "Control/Mode Change - Channel 5"; byte1text: "52"; ccNameText: "LSB for Control 20 (Undefined)"; ccNameShort: "LSB for CC 0x14"; value: 0xB4; messageSize: 3 }
        ListElement { byte0text: "Control/Mode Change - Channel 6"; byte1text: "53"; ccNameText: "LSB for Control 21 (Undefined)"; ccNameShort: "LSB for CC 0x15"; value: 0xB5; messageSize: 3 }
        ListElement { byte0text: "Control/Mode Change - Channel 7"; byte1text: "54"; ccNameText: "LSB for Control 22 (Undefined)"; ccNameShort: "LSB for CC 0x16"; value: 0xB6; messageSize: 3 }
        ListElement { byte0text: "Control/Mode Change - Channel 8"; byte1text: "55"; ccNameText: "LSB for Control 23 (Undefined)"; ccNameShort: "LSB for CC 0x17"; value: 0xB7; messageSize: 3 }
        ListElement { byte0text: "Control/Mode Change - Channel 9"; byte1text: "56"; ccNameText: "LSB for Control 24 (Undefined)"; ccNameShort: "LSB for CC 0x18"; value: 0xB8; messageSize: 3 }
        ListElement { byte0text: "Control/Mode Change - Channel 10"; byte1text: "57"; ccNameText: "LSB for Control 25 (Undefined)"; ccNameShort: "LSB for CC 0x19"; value: 0xB9; messageSize: 3 }
        ListElement { byte0text: "Control/Mode Change - Channel 11"; byte1text: "58"; ccNameText: "LSB for Control 26 (Undefined)"; ccNameShort: "LSB for CC 0x1A"; value: 0xBA; messageSize: 3 }
        ListElement { byte0text: "Control/Mode Change - Channel 12"; byte1text: "59"; ccNameText: "LSB for Control 27 (Undefined)"; ccNameShort: "LSB for CC 0x1B"; value: 0xBB; messageSize: 3 }
        ListElement { byte0text: "Control/Mode Change - Channel 13"; byte1text: "60"; ccNameText: "LSB for Control 28 (Undefined)"; ccNameShort: "LSB for CC 0x1C"; value: 0xBC; messageSize: 3 }
        ListElement { byte0text: "Control/Mode Change - Channel 14"; byte1text: "61"; ccNameText: "LSB for Control 29 (Undefined)"; ccNameShort: "LSB for CC 0x1D"; value: 0xBD; messageSize: 3 }
        ListElement { byte0text: "Control/Mode Change - Channel 15"; byte1text: "62"; ccNameText: "LSB for Control 30 (Undefined)"; ccNameShort: "LSB for CC 0x1E"; value: 0xBE; messageSize: 3 }
        ListElement { byte0text: "Control/Mode Change - Channel 16"; byte1text: "63"; ccNameText: "LSB for Control 31 (Undefined)"; ccNameShort: "LSB for CC 0x1F"; value: 0xBF; messageSize: 3 }
        ListElement { byte0text: "Program Change - Channel 1"; byte1text: "64"; ccNameText: "Damper Pedal on/off (Sustain)"; ccNameShort: "Damper Pedal on/off"; value: 0xC0; messageSize: 2 }
        ListElement { byte0text: "Program Change - Channel 2"; byte1text: "65"; ccNameText: "Portamento On/Off"; ccNameShort: "Portamento On/Off"; value: 0xC1; messageSize: 2 }
        ListElement { byte0text: "Program Change - Channel 3"; byte1text: "66"; ccNameText: "Sostenuto On/Off"; ccNameShort: "Sostenuto On/Off"; value: 0xC2; messageSize: 2 }
        ListElement { byte0text: "Program Change - Channel 4"; byte1text: "67"; ccNameText: "Soft Pedal On/Off"; ccNameShort: "Soft Pedal On/Off"; value: 0xC3; messageSize: 2 }
        ListElement { byte0text: "Program Change - Channel 5"; byte1text: "68"; ccNameText: "Legato Footswitch"; ccNameShort: "Legato Footswitch"; value: 0xC4; messageSize: 2 }
        ListElement { byte0text: "Program Change - Channel 6"; byte1text: "69"; ccNameText: "Hold 2"; ccNameShort: "Hold 2"; value: 0xC5; messageSize: 2 }
        ListElement { byte0text: "Program Change - Channel 7"; byte1text: "70"; ccNameText: "Sound Controller 1 (default: Sound Variation)"; ccNameShort: "Sound Ctrl 1"; value: 0xC6; messageSize: 2 }
        ListElement { byte0text: "Program Change - Channel 8"; byte1text: "71"; ccNameText: "Sound Controller 2 (default: Timbre/Harmonic Intensity)"; ccNameShort: "Sound Ctrl 2"; value: 0xC7; messageSize: 2 }
        ListElement { byte0text: "Program Change - Channel 9"; byte1text: "72"; ccNameText: "Sound Controller 3 (default: Release Time)"; ccNameShort: "Sound Ctrl 3"; value: 0xC8; messageSize: 2 }
        ListElement { byte0text: "Program Change - Channel 10"; byte1text: "73"; ccNameText: "Sound Controller 4 (default: Attack Time)"; ccNameShort: "Sound Ctrl 4"; value: 0xC9; messageSize: 2 }
        ListElement { byte0text: "Program Change - Channel 11"; byte1text: "74"; ccNameText: "Sound Controller 5 (default: Brightness)"; ccNameShort: "Sound Ctrl 5"; value: 0xCA; messageSize: 2 }
        ListElement { byte0text: "Program Change - Channel 12"; byte1text: "75"; ccNameText: "Sound Controller 6 (default: Decay Time)"; ccNameShort: "Sound Ctrl 6"; value: 0xCB; messageSize: 2 }
        ListElement { byte0text: "Program Change - Channel 13"; byte1text: "76"; ccNameText: "Sound Controller 7 (default: Vibrato Rate)"; ccNameShort: "Sound Ctrl 7"; value: 0xCC; messageSize: 2 }
        ListElement { byte0text: "Program Change - Channel 14"; byte1text: "77"; ccNameText: "Sound Controller 8 (default: Vibrato Depth)"; ccNameShort: "Sound Ctrl 8"; value: 0xCD; messageSize: 2 }
        ListElement { byte0text: "Program Change - Channel 15"; byte1text: "78"; ccNameText: "Sound Controller 9 (default: Vibrato Delay"; ccNameShort: "Sound Ctrl 9"; value: 0xCE; messageSize: 2 }
        ListElement { byte0text: "Program Change - Channel 16"; byte1text: "79"; ccNameText: "Sound Controller 10 (default undefined)"; ccNameShort: "Sound Ctrl 10"; value: 0xCF; messageSize: 2 }
        ListElement { byte0text: "Channel Aftertouch - Channel 1"; byte1text: "80"; ccNameText: "General Purpose Controller 5"; ccNameShort: "General Purpose 5"; value: 0xD0; messageSize: 3 }
        ListElement { byte0text: "Channel Aftertouch - Channel 2"; byte1text: "81"; ccNameText: "General Purpose Controller 6"; ccNameShort: "General Purpose 6"; value: 0xD1; messageSize: 3 }
        ListElement { byte0text: "Channel Aftertouch - Channel 3"; byte1text: "82"; ccNameText: "General Purpose Controller 7"; ccNameShort: "General Purpose 7"; value: 0xD2; messageSize: 3 }
        ListElement { byte0text: "Channel Aftertouch - Channel 4"; byte1text: "83"; ccNameText: "General Purpose Controller 8"; ccNameShort: "General Purpose 8"; value: 0xD3; messageSize: 3 }
        ListElement { byte0text: "Channel Aftertouch - Channel 5"; byte1text: "84"; ccNameText: "Portamento Control"; ccNameShort: "Portamento Control"; value: 0xD4; messageSize: 3 }
        ListElement { byte0text: "Channel Aftertouch - Channel 6"; byte1text: "85"; ccNameText: "Undefined (0x55)"; ccNameShort: "CC 0x55"; value: 0xD5; messageSize: 3 }
        ListElement { byte0text: "Channel Aftertouch - Channel 7"; byte1text: "86"; ccNameText: "Undefined (0x56)"; ccNameShort: "CC 0x56"; value: 0xD6; messageSize: 3 }
        ListElement { byte0text: "Channel Aftertouch - Channel 8"; byte1text: "87"; ccNameText: "Undefined (0x57)"; ccNameShort: "CC 0x57"; value: 0xD7; messageSize: 3 }
        ListElement { byte0text: "Channel Aftertouch - Channel 9"; byte1text: "88"; ccNameText: "High Resolution Velocity Prefix"; ccNameShort: "High Res Vel Prefix"; value: 0xD8; messageSize: 3 }
        ListElement { byte0text: "Channel Aftertouch - Channel 10"; byte1text: "89"; ccNameText: "Undefined (0x59)"; ccNameShort: "CC 0x59"; value: 0xD9; messageSize: 3 }
        ListElement { byte0text: "Channel Aftertouch - Channel 11"; byte1text: "90"; ccNameText: "Undefined (0x5A)"; ccNameShort: "CC 0x5A"; value: 0xDA; messageSize: 3 }
        ListElement { byte0text: "Channel Aftertouch - Channel 12"; byte1text: "91"; ccNameText: "Effects 1 Depth (default: Reverb Send Level)"; ccNameShort: "FX 1 Depth"; value: 0xDB; messageSize: 3 }
        ListElement { byte0text: "Channel Aftertouch - Channel 13"; byte1text: "92"; ccNameText: "Effects 2 Depth (formerly Tremolo Depth)"; ccNameShort: "FX 2 Depth"; value: 0xDC; messageSize: 3 }
        ListElement { byte0text: "Channel Aftertouch - Channel 14"; byte1text: "93"; ccNameText: "Effects 3 Depth (default: Chorus Send Level)"; ccNameShort: "FX 3 Depth"; value: 0xDD; messageSize: 3 }
        ListElement { byte0text: "Channel Aftertouch - Channel 15"; byte1text: "94"; ccNameText: "Effects 4 Depth (formerly Celeste [Detune] Depth)"; ccNameShort: "FX 4 Depth"; value: 0xDE; messageSize: 3 }
        ListElement { byte0text: "Channel Aftertouch - Channel 16"; byte1text: "95"; ccNameText: "Effects 5 Depth (formerly Phaser Depth)"; ccNameShort: "FX 5 Depth"; value: 0xDF; messageSize: 3 }
        ListElement { byte0text: "Pitch Wheel - Channel 1"; byte1text: "96"; ccNameText: "Data Increment (Data Entry +1)"; ccNameShort: "Data Increment"; value: 0xE0; messageSize: 3 }
        ListElement { byte0text: "Pitch Wheel - Channel 2"; byte1text: "97"; ccNameText: "Data Decrement (Data Entry -1)"; ccNameShort: "Data Decrement"; value: 0xE1; messageSize: 3 }
        ListElement { byte0text: "Pitch Wheel - Channel 3"; byte1text: "98"; ccNameText: "Non-Registered Parameter Number (NRPN) – LSB"; ccNameShort: "NRPN LSB"; value: 0xE2; messageSize: 3 }
        ListElement { byte0text: "Pitch Wheel - Channel 4"; byte1text: "99"; ccNameText: "Non-Registered Parameter Number (NRPN) – MSB"; ccNameShort: "NRPN MSB"; value: 0xE3; messageSize: 3 }
        ListElement { byte0text: "Pitch Wheel - Channel 5"; byte1text: "100"; ccNameText: "Registered Parameter Number (RPN) – LSB"; ccNameShort: "RPN LSB"; value: 0xE4; messageSize: 3 }
        ListElement { byte0text: "Pitch Wheel - Channel 6"; byte1text: "101"; ccNameText: "Registered Parameter Number (RPN) – MSB"; ccNameShort: "RPN MSB"; value: 0xE5; messageSize: 3 }
        ListElement { byte0text: "Pitch Wheel - Channel 7"; byte1text: "102"; ccNameText: "Undefined (0x66)"; ccNameShort: "CC 0x66"; value: 0xE6; messageSize: 3 }
        ListElement { byte0text: "Pitch Wheel - Channel 8"; byte1text: "103"; ccNameText: "Undefined (0x67)"; ccNameShort: "CC 0x67"; value: 0xE7; messageSize: 3 }
        ListElement { byte0text: "Pitch Wheel - Channel 9"; byte1text: "104"; ccNameText: "Undefined (0x68)"; ccNameShort: "CC 0x68"; value: 0xE8; messageSize: 3 }
        ListElement { byte0text: "Pitch Wheel - Channel 10"; byte1text: "105"; ccNameText: "Undefined (0x69)"; ccNameShort: "CC 0x69"; value: 0xE9; messageSize: 3 }
        ListElement { byte0text: "Pitch Wheel - Channel 11"; byte1text: "106"; ccNameText: "Undefined (0x6A)"; ccNameShort: "CC 0x6A"; value: 0xEA; messageSize: 3 }
        ListElement { byte0text: "Pitch Wheel - Channel 12"; byte1text: "107"; ccNameText: "Undefined (0x6B)"; ccNameShort: "CC 0x6B"; value: 0xEB; messageSize: 3 }
        ListElement { byte0text: "Pitch Wheel - Channel 13"; byte1text: "108"; ccNameText: "Undefined (0x6C)"; ccNameShort: "CC 0x6C"; value: 0xEC; messageSize: 3 }
        ListElement { byte0text: "Pitch Wheel - Channel 14"; byte1text: "109"; ccNameText: "Undefined (0x6D)"; ccNameShort: "CC 0x6D"; value: 0xED; messageSize: 3 }
        ListElement { byte0text: "Pitch Wheel - Channel 15"; byte1text: "110"; ccNameText: "Undefined (0x6E)"; ccNameShort: "CC 0x6E"; value: 0xEE; messageSize: 3 }
        ListElement { byte0text: "Pitch Wheel - Channel 16"; byte1text: "111"; ccNameText: "Undefined (0x6F)"; ccNameShort: "CC 0x6F"; value: 0xEF; messageSize: 3 }
        ListElement { byte0text: "System Exclusive"; byte1text: "112"; ccNameText: "Undefined (0x70)"; ccNameShort: "CC 0x7a"; value: 0xF0; messageSize: 1 }
        ListElement { byte0text: "MIDI Time Code Quarter Frame"; byte1text: "113"; ccNameText: "Undefined (0x71)"; ccNameShort: "CC 0x71"; value: 0xF1; messageSize: 3 }
        ListElement { byte0text: "Song Position Pointer"; byte1text: "114"; ccNameText: "Undefined (0x72)"; ccNameShort: "CC 0x72"; value: 0xF2; messageSize: 3 }
        ListElement { byte0text: "Song Select"; byte1text: "115"; ccNameText: "Undefined (0x73)"; ccNameShort: "CC 0x73"; value: 0xF3; messageSize: 2 }
        ListElement { byte0text: "Undefined (0xF3)"; byte1text: "116"; ccNameText: "Undefined (0x74)"; ccNameShort: "CC 0x74"; value: 0xF4; messageSize: 3 }
        ListElement { byte0text: "Undefined (0xF4)"; byte1text: "117"; ccNameText: "Undefined (0x75)"; ccNameShort: "CC 0x75"; value: 0xF5; messageSize: 3 }
        ListElement { byte0text: "Tune request"; byte1text: "118"; ccNameText: "Undefined (0x76)"; ccNameShort: "CC 0x76"; value: 0xF6; messageSize: 1 }
        ListElement { byte0text: "End of SysEx (EOX)"; byte1text: "119"; ccNameText: "Undefined (0x77)"; ccNameShort: "CC 0x77"; value: 0xF7; messageSize: 1 }
        ListElement { byte0text: "Timing Clock"; byte1text: "120"; ccNameText: "[Channel Mode Message] All Sound Off"; ccNameShort: "All Sound Off"; value: 0xF8; messageSize: 1 }
        ListElement { byte0text: "Undefined (0xF9)"; byte1text: "121"; ccNameText: "[Channel Mode Message] Reset All Controllers"; ccNameShort: "Reset All Ctrls"; value: 0xF9; messageSize: 1 }
        ListElement { byte0text: "Start"; byte1text: "122"; ccNameText: "[Channel Mode Message] Local Control On/Off"; ccNameShort: "Local Ctrl On/Off"; value: 0xFA; messageSize: 1 }
        ListElement { byte0text: "Continue"; byte1text: "123"; ccNameText: "[Channel Mode Message] All Notes Off"; ccNameShort: "All Notes Off"; value: 0xFB; messageSize: 1 }
        ListElement { byte0text: "Stop"; byte1text: "124"; ccNameText: "[Channel Mode Message] Omni Mode Off (+ all notes off)"; ccNameShort: "Omni Mode Off"; value: 0xFC; messageSize: 1 }
        ListElement { byte0text: "Undefined (0xFD)"; byte1text: "125"; ccNameText: "[Channel Mode Message] Omni Mode On (+ all notes off)"; ccNameShort: "Omni Mode On"; value: 0xFD; messageSize: 1 }
        ListElement { byte0text: "Active Sensing"; byte1text: "126"; ccNameText: "[Channel Mode Message] Mono Mode On (+ poly off, + all notes off)"; ccNameShort: "Mono Mode On"; value: 0xFE; messageSize: 1 }
        ListElement { byte0text: "System Reset"; byte1text: "127"; ccNameText: "[Channel Mode Message] Poly Mode On (+ mono off, +all notes off)"; ccNameShort: "Poly Mode On"; value: 0xFF; messageSize: 1 }
    }
    textRole: byteType === 0
        ? "byte0text"
        : byteType === 1
            ? "byte1text"
            : byteType === 2
                ? "ccNameText"
                : "value"
    onActivated: function(activatedIndex) {
        let selectedElement = component.model.get(activatedIndex);
        if (component.byteType === 0) {
            component.byteValue = selectedElement.value;
        } else {
            component.byteValue = selectedElement.value - 128; // Also the index, but...
        }
        component.messageSize = selectedElement.messageSize;
        if (component.callbackFunction) {
            component.callbackFunction(component.byteValue, component.messageSize);
        }
    }
}
