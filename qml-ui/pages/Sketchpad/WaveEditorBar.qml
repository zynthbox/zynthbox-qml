/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Loopgrid Page

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Marco MArtin <mart@kde.org>

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
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Qt.labs.folderlistmodel 2.11

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

// GridLayout so TabbedControlView knows how to navigate it
GridLayout {
    id: waveBar
    rows: 1
    Layout.fillWidth: true
    property QtObject bottomBar: null
    property string controlType: zynqtgui.bottomBarControlType
    property QtObject controlObj: (waveBar.controlType === "bottombar-controltype-clip" || waveBar.controlType === "bottombar-controltype-pattern")
                                    ? zynqtgui.bottomBarControlObj // selected bottomBar object is clip/pattern
                                    : zynqtgui.bottomBarControlObj != null && zynqtgui.bottomBarControlObj.samples != null
                                        ? zynqtgui.bottomBarControlObj.samples[zynqtgui.bottomBarControlObj.selectedSlotRow] // selected bottomBar object is not clip/pattern and hence it is a channel
                                        : null
    property QtObject cppClipObject: waveBar.controlObj && waveBar.controlObj.hasOwnProperty("cppObjId")
                                        ? Zynthbox.PlayGridManager.getClipById(waveBar.controlObj.cppObjId)
                                        : null
    property QtObject channel: zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId)

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
                bottomStack.slotsBar.channelButton.checked = true
                return true;
            case "KNOB0_TOUCHED":
                if (waveBar.cppClipObject) {
                    if (waveBar.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                        wav.focusSection(waveBar.cppClipObject.startPositionSamples, waveBar.cppClipObject.lengthSamples);
                    } else {
                        if (pinchZoomer.scale > 1) {
                            wav.focusPosition(waveBar.cppClipObject.startPositionSamples);
                        }
                    }
                }
                return true;
                break;
            case "KNOB1_TOUCHED":
                if (waveBar.cppClipObject) {
                    if (waveBar.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                        wav.focusSection(waveBar.cppClipObject.startPositionSamples, waveBar.cppClipObject.lengthSamples);
                    } else {
                        if (pinchZoomer.scale > 1) {
                            wav.focusPosition(waveBar.cppClipObject.startPositionSamples + waveBar.cppClipObject.loopDeltaSamples);
                        }
                    }
                }
                return true;
                break;
            case "KNOB2_TOUCHED":
                if (waveBar.cppClipObject) {
                    if (waveBar.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                        wav.focusSection(waveBar.cppClipObject.startPositionSamples, waveBar.cppClipObject.lengthSamples);
                    } else {
                        if (pinchZoomer.scale > 1) {
                            wav.focusPosition(waveBar.cppClipObject.startPositionSamples + waveBar.cppClipObject.lengthSamples);
                        }
                    }
                }
                return true;
                break;
            case "KNOB3_TOUCHED":
                return true;
            case "KNOB0_UP":
                if (waveBar.cppClipObject && waveBar.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                    if (zynqtgui.modeButtonPressed) {
                        zynqtgui.ignoreNextModeButtonPress = true;
                        waveBar.cppClipObject.startPositionSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.startPositionSamples + 1, 0, waveBar.cppClipObject.durationSamples - waveBar.cppClipObject.lengthSamples);
                    } else {
                        waveBar.cppClipObject.startPositionSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.startPositionSamples + waveBar.cppClipObject.lengthSamples, 0, waveBar.cppClipObject.durationSamples - waveBar.cppClipObject.lengthSamples);
                    }
                    wav.focusSection(waveBar.cppClipObject.startPositionSamples, waveBar.cppClipObject.lengthSamples);
                } else {
                    if (zynqtgui.modeButtonPressed) {
                        zynqtgui.ignoreNextModeButtonPress = true;
                        waveBar.cppClipObject.startPositionSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.startPositionSamples + 1, 0, waveBar.cppClipObject.durationSamples);
                    } else {
                        waveBar.cppClipObject.startPositionSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.startPositionSamples + wav.samplesPerPixel, 0, waveBar.cppClipObject.durationSamples);
                    }
                    if (pinchZoomer.scale > 1) {
                        wav.focusPosition(waveBar.cppClipObject.startPositionSamples);
                    }
                }
                return true;
            case "KNOB0_DOWN":
                if (waveBar.cppClipObject && waveBar.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                    if (zynqtgui.modeButtonPressed) {
                        zynqtgui.ignoreNextModeButtonPress = true;
                        waveBar.cppClipObject.startPositionSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.startPositionSamples - 1, 0, waveBar.cppClipObject.durationSamples - waveBar.cppClipObject.lengthSamples);
                    } else {
                        waveBar.cppClipObject.startPositionSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.startPositionSamples - waveBar.cppClipObject.lengthSamples, 0, waveBar.cppClipObject.durationSamples - waveBar.cppClipObject.lengthSamples);
                    }
                    wav.focusSection(waveBar.cppClipObject.startPositionSamples, waveBar.cppClipObject.lengthSamples);
                } else {
                    if (zynqtgui.modeButtonPressed) {
                        zynqtgui.ignoreNextModeButtonPress = true;
                        waveBar.cppClipObject.startPositionSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.startPositionSamples - 1, 0, waveBar.cppClipObject.durationSamples);
                    } else {
                        waveBar.cppClipObject.startPositionSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.startPositionSamples - wav.samplesPerPixel, 0, waveBar.cppClipObject.durationSamples);
                    }
                    if (pinchZoomer.scale > 1) {
                        wav.focusPosition(waveBar.cppClipObject.startPositionSamples);
                    }
                }
                return true;
            case "KNOB1_UP":
                if (waveBar.cppClipObject && waveBar.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                    // No loop delta to work on with the wavetable style sounds (it's locked to 0)
                } else {
                    if (waveBar.cppClipObject.snapLengthToBeat) {
                        waveBar.cppClipObject.loopDelta = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.loopDelta + (60 / waveBar.cppClipObject.bpm), 0, waveBar.cppClipObject.lengthSeconds);
                    } else {
                        if (zynqtgui.modeButtonPressed) {
                            zynqtgui.ignoreNextModeButtonPress = true;
                            waveBar.cppClipObject.loopDeltaSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.loopDeltaSamples + 1, 0, waveBar.cppClipObject.lengthSamples);
                        } else {
                            waveBar.cppClipObject.loopDeltaSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.loopDeltaSamples + wav.samplesPerPixel, 0, waveBar.cppClipObject.lengthSamples);
                        }
                    }
                    if (pinchZoomer.scale > 1) {
                        wav.focusPosition(waveBar.cppClipObject.startPositionSamples + waveBar.cppClipObject.loopDeltaSamples);
                    }
                }
                return true;
            case "KNOB1_DOWN":
                if (waveBar.cppClipObject && waveBar.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                    // No loop delta to work on with the wavetable style sounds (it's locked to 0)
                } else {
                    if (waveBar.cppClipObject.snapLengthToBeat) {
                        waveBar.cppClipObject.loopDelta = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.loopDelta - (60 / waveBar.cppClipObject.bpm), 0, waveBar.cppClipObject.lengthSeconds);
                    } else {
                        if (zynqtgui.modeButtonPressed) {
                            zynqtgui.ignoreNextModeButtonPress = true;
                            waveBar.cppClipObject.loopDeltaSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.loopDeltaSamples - 1, 0, waveBar.cppClipObject.lengthSamples);
                        } else {
                            waveBar.cppClipObject.loopDeltaSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.loopDeltaSamples - wav.samplesPerPixel, 0, waveBar.cppClipObject.lengthSamples);
                        }
                    }
                    if (pinchZoomer.scale > 1) {
                        wav.focusPosition(waveBar.cppClipObject.startPositionSamples + waveBar.cppClipObject.loopDeltaSamples);
                    }
                }
                return true;
            case "KNOB2_UP":
                if (waveBar.cppClipObject && waveBar.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                    if (zynqtgui.modeButtonPressed) {
                        zynqtgui.ignoreNextModeButtonPress = true;
                        if (waveBar.cppClipObject.lengthSamples < waveBar.cppClipObject.durationSamples) {
                            waveBar.cppClipObject.lengthSamples = waveBar.cppClipObject.lengthSamples + 1;
                        }
                    } else {
                        let currentDivision = Math.round(waveBar.cppClipObject.durationSamples / Math.max(1, waveBar.cppClipObject.lengthSamples));
                        if (currentDivision > 1) {
                            waveBar.cppClipObject.lengthSamples = waveBar.cppClipObject.durationSamples / (currentDivision - 1);
                        }
                    }
                    wav.focusSection(waveBar.cppClipObject.startPositionSamples, waveBar.cppClipObject.lengthSamples);
                } else {
                    if (waveBar.cppClipObject.snapLengthToBeat) {
                        waveBar.cppClipObject.lengthBeats = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.lengthBeats + 1, 0, 64);
                    } else {
                        if (zynqtgui.modeButtonPressed) {
                            zynqtgui.ignoreNextModeButtonPress = true;
                            waveBar.cppClipObject.lengthSamples = waveBar.cppClipObject.lengthSamples + 1;
                        } else {
                            waveBar.cppClipObject.lengthSamples = waveBar.cppClipObject.lengthSamples + wav.samplesPerPixel;
                        }
                    }
                    if (pinchZoomer.scale > 1) {
                        wav.focusPosition(waveBar.cppClipObject.startPositionSamples + waveBar.cppClipObject.lengthSamples);
                    }
                }
                return true;
            case "KNOB2_DOWN":
                if (waveBar.cppClipObject && waveBar.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                    if (zynqtgui.modeButtonPressed) {
                        zynqtgui.ignoreNextModeButtonPress = true;
                        if (waveBar.cppClipObject.lengthSamples > 1) {
                            waveBar.cppClipObject.lengthSamples = waveBar.cppClipObject.lengthSamples - 1;
                        }
                    } else {
                        let currentDivision = Math.round(waveBar.cppClipObject.durationSamples / Math.max(1, waveBar.cppClipObject.lengthSamples));
                        if (currentDivision < waveBar.cppClipObject.durationSamples) {
                            waveBar.cppClipObject.lengthSamples = waveBar.cppClipObject.durationSamples / (currentDivision + 1);
                        }
                    }
                    wav.focusSection(waveBar.cppClipObject.startPositionSamples, waveBar.cppClipObject.lengthSamples);
                } else {
                    if (waveBar.cppClipObject.snapLengthToBeat) {
                        waveBar.cppClipObject.lengthBeats = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.lengthBeats - 1, 0, 64);
                    } else {
                        if (zynqtgui.modeButtonPressed) {
                            zynqtgui.ignoreNextModeButtonPress = true;
                            waveBar.cppClipObject.lengthSamples = Math.max(0, waveBar.cppClipObject.lengthSamples - 1);
                        } else {
                            waveBar.cppClipObject.lengthSamples = Math.max(0, waveBar.cppClipObject.lengthSamples - wav.samplesPerPixel);
                        }
                    }
                    if (pinchZoomer.scale > 1) {
                        wav.focusPosition(waveBar.cppClipObject.startPositionSamples + waveBar.cppClipObject.lengthSamples);
                    }
                }
                return true;
            case "KNOB3_UP":
                return true;
            case "KNOB3_DOWN":
                return true;
        }

        return false;
    }
    clip: true

    Zynthbox.WaveFormItem {
        id: wav

        // Calculate amount of pixels represented by 1 second
        property real pixelToSecs: (wav.end - wav.start) / width

        // Calculate the amount of samples in one pixel (at least one)
        readonly property int startSample: waveBar.cppClipObject ? waveBar.cppClipObject.durationSamples * wav.start / wav.length : 0
        readonly property int endSample: waveBar.cppClipObject ? waveBar.cppClipObject.durationSamples * wav.end / wav.length : 1
        readonly property real samplesPerPixel: waveBar.cppClipObject ? Math.max(1, (wav.endSample - wav.startSample) / wav.width) : 1

        // Calculate amount of pixels represented by 1 beat
        property real pixelsPerBeat: waveBar.cppClipObject ? (60/waveBar.cppClipObject.bpm) / wav.pixelToSecs : 1

        function fitInWindow(originalX, windowStart, windowEnd) {
            let movedX = originalX - windowStart;
            let windowSize = windowEnd - windowStart;
            let windowRatio = windowSize / 1;
            return movedX / windowRatio;
        }
        function focusPosition(positionToFocus) {
            pinchZoomer.position = Math.max(0, Math.min((positionToFocus - (wav.windowSizeSamples * 0.5)) / (waveBar.cppClipObject.durationSamples - wav.windowSizeSamples), 1));
        }
        function focusSection(startPointInSamples, sectionLengthInSamples, focusOffset) {
            if (focusOffset == undefined) {
                focusOffset = 0.5;
            }
            pinchZoomer.scale = (waveBar.cppClipObject.durationSamples) / (sectionLengthInSamples * 2);
            let zoomPoint = (startPointInSamples - (sectionLengthInSamples * focusOffset));
            pinchZoomer.position = Math.max(0, Math.min(zoomPoint / (waveBar.cppClipObject.durationSamples - (sectionLengthInSamples * 2)), 1));
            // console.log("Setting new scale and position to fit the selected window", pinchZoomer.scale, pinchZoomer.position);
        }

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: Kirigami.Units.gridUnit
        Layout.bottomMargin: pinchZoomer.scale > 1 ? Kirigami.Units.gridUnit + waveBar.height * 0.1 : Kirigami.Units.gridUnit
        color: Kirigami.Theme.textColor
        Timer {
            id: waveFormThrottle
            interval: 1; running: false; repeat: false;
            onTriggered: {
                wav.source = waveBar.controlObj && waveBar.controlObj.path != null ? waveBar.controlObj.path : ""
                if (waveBar.cppClipObject && waveBar.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                    wav.focusSection(waveBar.cppClipObject.startPositionSamples, waveBar.cppClipObject.lengthSamples);
                } else {
                    pinchZoomer.scale = 1;
                    pinchZoomer.position = 0;
                }
            }
        }
        Connections {
            target: waveBar
            onControlObjChanged: waveFormThrottle.restart()
            onCppClipObjectChanged: waveFormThrottle.restart()
        }
        Connections {
            target: waveBar.controlObj && waveBar.controlObj.hasOwnProperty("path") ? waveBar.controlObj : null
            onPath_changed: waveFormThrottle.restart()
        }
        Component.onCompleted: {
            waveFormThrottle.restart();
        }

        start: Math.min(pinchZoomer.position * (wav.length - wav.windowSize), wav.length - wav.windowSize)
        end: Math.min(wav.start + wav.windowSize, wav.length)
        readonly property real windowSize: wav.length / pinchZoomer.scale
        readonly property int windowSizeSamples: waveBar.cppClipObject ? waveBar.cppClipObject.durationSamples / pinchZoomer.scale : 1
        // onStartChanged: console.log("Start changed to", wav.start)
        // onEndChanged: console.log("End changed to", wav.end)
        // onWindowSizeChanged: console.log("Window size changed to", wav.windowSize)
        // onSourceChanged: console.log("Source changed to", wav.source)

        readonly property real relativeStart: wav.start / wav.length
        readonly property real relativeEnd: wav.end / wav.length

        PinchArea {
            id: pinchZoomer
            anchors.fill: parent
            property real scale: 1
            property real position: 0
            property real inProcessScale: 1
            onPinchStarted: {
                inProcessScale = scale;
            }
            onPinchUpdated: {
                scale = Math.max(1, Math.min(inProcessScale + pinch.scale, 100));
                // console.log("Updated scale:", scale);
            }
            onPinchFinished: {
                scale = Math.max(1, Math.min(inProcessScale + pinch.scale, 100));
                // console.log("Finished scale:", scale);
            }
            MouseArea {
                id: pinchMouseArea
                anchors.fill: parent
                onDoubleClicked: {
                    if (pinchZoomer.scale == 1) {
                        // Zoom in to fit the current window size (that is, fit twice the size of the window, and then position it in the centre of the viewport)
                        wav.focusSection(waveBar.cppClipObject.startPositionSamples, waveBar.cppClipObject.lengthSamples);
                    } else {
                        pinchZoomer.scale = 1;
                        pinchZoomer.position = 0;
                        // console.log("Resetting scale and position to fit all", pinchZoomer.scale, pinchZoomer.position);
                    }
                }
                readonly property int oneThird: height / 3
                readonly property int twoThirds: oneThird * 2
                property int initialX: 0
                property int pressedY: 0
                property int initialStartPositionSamples: 0
                property int initialLoopDeltaSamples: 0
                property int initialLoopDelta: 0
                property int initialLengthSamples: 0
                property int initialLengthBeats: 0
                onPressed: {
                    initialX = mouse.x;
                    pressedY = mouse.y;
                    if (waveBar.cppClipObject) {
                        pinchMouseArea.initialStartPositionSamples = waveBar.cppClipObject.startPositionSamples;
                        pinchMouseArea.initialLoopDeltaSamples = waveBar.cppClipObject.loopDeltaSamples;
                        pinchMouseArea.initialLoopDelta = waveBar.cppClipObject.loopDelta;
                        pinchMouseArea.initialLengthSamples = waveBar.cppClipObject.lengthSamples;
                        pinchMouseArea.initialLengthBeats = waveBar.cppClipObject.lengthBeats;
                    }
                }
                onPositionChanged: {
                    // Don't try and do the setty thing if there's a pinch happening
                    if (pinchZoomer.pinch.active === false && waveBar.cppClipObject) {
                        let deltaX = mouse.x - pinchMouseArea.initialX;
                        if (pressedY < oneThird) {
                            // Upper third (start point)
                            if (waveBar.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                                if (zynqtgui.modeButtonPressed) {
                                    zynqtgui.ignoreNextModeButtonPress = true;
                                    waveBar.cppClipObject.startPositionSamples = Zynthian.CommonUtils.clamp(pinchMouseArea.initialStartPositionSamples + deltaX, 0, waveBar.cppClipObject.durationSamples - waveBar.cppClipObject.lengthSamples);
                                } else {
                                    waveBar.cppClipObject.startPositionSamples = Zynthian.CommonUtils.clamp(pinchMouseArea.initialStartPositionSamples + (deltaX * waveBar.cppClipObject.lengthSamples), 0, waveBar.cppClipObject.durationSamples - waveBar.cppClipObject.lengthSamples);
                                }
                                wav.focusSection(waveBar.cppClipObject.startPositionSamples, waveBar.cppClipObject.lengthSamples);
                            } else {
                                if (zynqtgui.modeButtonPressed) {
                                    zynqtgui.ignoreNextModeButtonPress = true;
                                    waveBar.cppClipObject.startPositionSamples = Zynthian.CommonUtils.clamp(pinchMouseArea.initialStartPositionSamples + deltaX, 0, waveBar.cppClipObject.durationSamples);
                                } else {
                                    waveBar.cppClipObject.startPositionSamples = Zynthian.CommonUtils.clamp(pinchMouseArea.initialStartPositionSamples + (deltaX * wav.samplesPerPixel), 0, waveBar.cppClipObject.durationSamples);
                                }
                            }
                        } else if (pressedY < twoThirds) {
                            // Centre third (loop point) - this may need some fanciness going on when we add in loopDelta2
                            if (waveBar.cppClipObject && waveBar.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                                // No loop delta to work on with the wavetable style sounds (it's locked to 0)
                            } else {
                                if (waveBar.cppClipObject.snapLengthToBeat) {
                                    waveBar.cppClipObject.loopDelta = Zynthian.CommonUtils.clamp(pinchMouseArea.initialLoopDelta + (Math.round(deltaX / wav.pixelsPerBeat) * wav.pixelsPerBeat * wav.pixelToSecs), 0, waveBar.cppClipObject.lengthSeconds);
                                } else {
                                    if (zynqtgui.modeButtonPressed) {
                                        zynqtgui.ignoreNextModeButtonPress = true;
                                        waveBar.cppClipObject.loopDeltaSamples = Zynthian.CommonUtils.clamp(pinchMouseArea.initialLoopDeltaSamples + deltaX, 0, waveBar.cppClipObject.lengthSamples);
                                    } else {
                                        waveBar.cppClipObject.loopDeltaSamples = Zynthian.CommonUtils.clamp(pinchMouseArea.initialLoopDeltaSamples + (deltaX * wav.samplesPerPixel), 0, waveBar.cppClipObject.lengthSamples);
                                    }
                                }
                            }
                        } else {
                            // Lower third (end point)
                            if (waveBar.cppClipObject && waveBar.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                                if (zynqtgui.modeButtonPressed) {
                                    zynqtgui.ignoreNextModeButtonPress = true;
                                    waveBar.cppClipObject.lengthSamples = Math.min(pinchMouseArea.initialLengthSamples + deltaX, waveBar.cppClipObject.durationSamples);
                                } else {
                                    let currentDivision = Math.round(waveBar.cppClipObject.durationSamples / Math.max(1, pinchMouseArea.initialLengthSamples));
                                    if (currentDivision > 1) {
                                        waveBar.cppClipObject.lengthSamples = waveBar.cppClipObject.durationSamples / (currentDivision - Math.round(deltaX / Kirigami.Units.gridUnit));
                                    }
                                }
                                wav.focusSection(waveBar.cppClipObject.startPositionSamples, waveBar.cppClipObject.lengthSamples);
                            } else {
                                if (waveBar.cppClipObject.snapLengthToBeat) {
                                    waveBar.cppClipObject.lengthBeats = Zynthian.CommonUtils.clamp(pinchMouseArea.initialLengthBeats + Math.round(deltaX / wav.pixelsPerBeat), 0, 64);
                                } else {
                                    if (zynqtgui.modeButtonPressed) {
                                        zynqtgui.ignoreNextModeButtonPress = true;
                                        waveBar.cppClipObject.lengthSamples = Math.max(0, pinchMouseArea.initialLengthSamples + deltaX);
                                    } else {
                                        waveBar.cppClipObject.lengthSamples = Math.max(0, pinchMouseArea.initialLengthSamples + (deltaX * wav.samplesPerPixel));
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Mask for wave part before the playback window
        Rectangle {
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                right: startLoopLine.left
            }
            color: "#99000000"
        }

        // Mask for wave part after the playback window
        Rectangle {
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: endLoopLine.right
                right: parent.right
            }
            color: "#99000000"
        }

        Zynthbox.WaveFormItem {
            id: scrollingViewport
            anchors {
                left: parent.left
                right: parent.right
                top: parent.bottom
                topMargin: Kirigami.Units.smallSpacing
            }
            height: waveBar.height * 0.1
            visible: pinchZoomer.scale > 1
            source: wav.source
            Rectangle {
                id: scrollGrooveLeft
                anchors {
                    top: parent.top
                    left: parent.left
                    bottom: parent.bottom
                }
                color: "#99000000"
                width: parent.width * wav.relativeStart
            }
            Rectangle {
                id: scrollGrooveRight
                anchors {
                    top: parent.top
                    right: parent.right
                    bottom: parent.bottom
                }
                color: "#99000000"
                width: parent.width * (1 - wav.relativeEnd)
            }
            Rectangle {
                anchors {
                    top: parent.top
                    left: scrollGrooveLeft.right
                    right: scrollGrooveRight.left
                    bottom: parent.bottom
                }
                color: Kirigami.Theme.focusColor
                opacity: 0.5
            }
            MouseArea {
                anchors.fill: parent
                onPositionChanged: {
                    pinchZoomer.position = Math.max(0, Math.min(mouse.x / width, 1));
                }
            }
        }

        // TODO Port underneath to match new zoom/pan logic

        // Handle for setting start position
        Item {
            anchors {
                left: startLoopLine.left
                top: startLoopLine.top
            }
            height: parent.height / 3
            width: startHandleLabel.paintedWidth + Kirigami.Units.largeSpacing * 3
            z: 100
            Image {
                anchors {
                    left: startHandleLabel.right
                    top: parent.top
                    bottom: parent.bottom
                    margins: Kirigami.Units.largeSpacing * 1.5
                }
                source: "../../Zynthian/img/breadcrumb-separator.svg"
            }
            Text {
                id: startHandleLabel
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                color: Kirigami.Theme.textColor
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
                anchors {
                    top: parent.top
                    left: parent.left
                    bottom: parent.bottom
                    margins: Kirigami.Units.largeSpacing * 1.5
                }
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                text: qsTr("S", "Start")
            }
        }

        // Handle for setting loop point
        Item {
            visible: waveBar.channel.trackType !== "sample-slice" && waveBar.cppClipObject && waveBar.cppClipObject.playbackStyle != Zynthbox.ClipAudioSource.WavetableStyle
            anchors {
                verticalCenter: loopLine.verticalCenter
                left: loopLine.right
            }
            height: parent.height / 3
            width: loopHandleLabel.paintedWidth + Kirigami.Units.largeSpacing * 3
            z: 100
            Image {
                anchors {
                    left: loopHandleLabel.right
                    top: parent.top
                    bottom: parent.bottom
                    margins: Kirigami.Units.largeSpacing * 1.5
                }
                source: "../../Zynthian/img/breadcrumb-separator.svg"
            }
            Text {
                id: loopHandleLabel
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                color: Kirigami.Theme.textColor
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
                anchors {
                    top: parent.top
                    left: parent.left
                    bottom: parent.bottom
                    margins: Kirigami.Units.largeSpacing * 1.5
                }
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                text: qsTr("L", "Loop")
            }
        }

        // Handle for setting length
        Item {
            anchors {
                right: endLoopLine.left
                bottom: parent.bottom
            }
            height: parent.height / 3
            width: endHandleLabel.paintedWidth + Kirigami.Units.largeSpacing * 3
            z: 100
            Image {
                anchors {
                    right: endHandleLabel.left
                    top: parent.top
                    bottom: parent.bottom
                    margins: Kirigami.Units.largeSpacing * 1.5
                }
                mirror: true
                source: "../../Zynthian/img/breadcrumb-separator.svg"
            }
            Text {
                id: endHandleLabel
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                color: Kirigami.Theme.textColor
                font.pointSize: waveBar.cppClipObject && waveBar.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle ? Kirigami.Theme.defaultFont.pointSize * 0.8 : Kirigami.Theme.defaultFont.pointSize * 1.2
                anchors {
                    top: parent.top
                    right: parent.right
                    bottom: parent.bottom
                    margins: Kirigami.Units.largeSpacing * 1.5
                }
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                property double currentDivision: waveBar.cppClipObject && waveBar.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle ? Math.round(waveBar.cppClipObject.durationSamples / Math.max(1, waveBar.cppClipObject.lengthSamples)) : 1
                text: waveBar.cppClipObject
                    ? waveBar.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle
                        ? "1/%1".arg(Number.isInteger(currentDivision) ? currentDivision : currentDivision.toFixed(2))
                        : qsTr("%1:%2 E", "End")
                            .arg(Math.floor(waveBar.cppClipObject.lengthBeats / 4))
                            .arg((waveBar.cppClipObject.lengthBeats % 4).toFixed(waveBar.cppClipObject.snapLengthToBeat ? 0 : 2))
                    : ""
            }
            Text {
                visible: waveBar.cppClipObject && waveBar.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                color: Kirigami.Theme.textColor
                font.pointSize: waveBar.cppClipObject && waveBar.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle ? Kirigami.Theme.defaultFont.pointSize * 0.8 : Kirigami.Theme.defaultFont.pointSize * 1.2
                anchors {
                    top: parent.top
                    left: parent.right
                    bottom: parent.bottom
                    margins: Kirigami.Units.largeSpacing * 1.5
                }
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                text: visible
                    ? qsTr("%1\nsamples").arg(waveBar.cppClipObject.lengthSamples)
                    : ""
            }
        }

        // Start loop line
        Rectangle {
            id: startLoopLine
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            color: Kirigami.Theme.positiveTextColor
            opacity: 0.6
            width: Math.max(1, 1 / wav.samplesPerPixel)
            property real startPositionRelative: waveBar.cppClipObject
                ? waveBar.cppClipObject.startPositionSamples / waveBar.cppClipObject.durationSamples
                : 1
            x: waveBar.cppClipObject
                ? wav.fitInWindow(startPositionRelative, wav.relativeStart, wav.relativeEnd) * parent.width
                : 0
        }

        // Loop line
        Rectangle {
            id: loopLine
            visible: waveBar.channel.trackType !== "sample-slice"
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            color: Kirigami.Theme.highlightColor
            opacity: 0.6
            width: startLoopLine.width
            property real loopDeltaRelative: waveBar.cppClipObject
                ? waveBar.cppClipObject.loopDeltaSamples / waveBar.cppClipObject.durationSamples
                : 0
            x: waveBar.cppClipObject
                ? wav.fitInWindow(startLoopLine.startPositionRelative + loopDeltaRelative, wav.relativeStart, wav.relativeEnd) * parent.width
                : 0
        }

        // End loop line
        Rectangle {
            id: endLoopLine
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            color: Kirigami.Theme.neutralTextColor
            opacity: 0.6
            width: startLoopLine.width
            x: waveBar.cppClipObject
                ? wav.fitInWindow(startLoopLine.startPositionRelative + (waveBar.cppClipObject.lengthSamples / waveBar.cppClipObject.durationSamples), wav.relativeStart, wav.relativeEnd) * parent.width
                : 0
        }

        // Progress line
        Rectangle {
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            visible: waveBar.visible && waveBar.channel.trackType === "sample-loop" && waveBar.cppClipObject && waveBar.cppClipObject.isPlaying
            color: Kirigami.Theme.highlightColor
            width: Kirigami.Units.smallSpacing
            x: visible ? wav.fitInWindow(waveBar.cppClipObject.position, wav.relativeStart, wav.relativeEnd) * parent.width * parent.width : 0
        }

        // SamplerSynth progress dots
        Repeater {
            id: progressDots
            model: (waveBar.visible && waveBar.channel.trackType === "sample-slice" || waveBar.channel.trackType === "sample-trig") && waveBar.cppClipObject
                    ? waveBar.cppClipObject.playbackPositions
                    : 0
            delegate: Item {
                visible: model.positionID > -1
                Rectangle {
                    anchors.centerIn: parent
                    rotation: 45
                    color: Kirigami.Theme.highlightColor
                    width: Kirigami.Units.largeSpacing
                    height:  Kirigami.Units.largeSpacing
                    scale: 0.5 + model.positionGain
                }
                anchors {
                    top: parent.verticalCenter
                    topMargin: model.positionPan * (parent.height / 2)
                }
                x: wav.fitInWindow(model.positionProgress, wav.relativeStart, wav.relativeEnd) * parent.width
            }
        }

        // Create and place beat lines when trackType !== "sample-slice"
        Repeater {
            // Count number of beat lines to be shown as per beat and visible width
            model: waveBar.channel.trackType !== "sample-slice"
                    ? Math.ceil(wav.width / wav.pixelsPerBeat)
                    : 0
            delegate: Rectangle {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                color: "#ffffff"
                opacity: 0.1
                width: 1
                // Calculate position of each beat line taking startposition into consideration
                x: wav.pixelsPerBeat*modelData + (startLoopLine.x % wav.pixelsPerBeat)
            }
        }

        // Create and place slice lines when trackType === "sample-slice"
        Repeater {
            // Count number of slice lines to be shown
            model: waveBar.channel.trackType === "sample-slice"
                    ? waveBar.controlObj.slices
                    : 0
            delegate: Rectangle {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                color: Qt.rgba(Kirigami.Theme.highlightColor.r,
                                Kirigami.Theme.highlightColor.g,
                                Kirigami.Theme.highlightColor.b,
                                index === 0 ? 0 : 0.8)
                width: 2
                // Calculate position of each beat line taking startposition into consideration
                x: startLoopLine.x + (endLoopLine.x - startLoopLine.x)*modelData/waveBar.controlObj.slices

                Rectangle {
                    width: Math.min(Kirigami.Units.gridUnit, (endLoopLine.x - startLoopLine.x)/waveBar.controlObj.slices - 4)
                    height: width
                    anchors {
                        left: parent.right
                        bottom: parent.bottom
                    }

                    border.width: 1
                    border.color: "#99ffffff"
                    color: Kirigami.Theme.backgroundColor

                    QQC2.Label {
                        anchors.centerIn: parent
                        text: qsTr("%L1").arg(index+1)
                        font.pointSize: Math.min(8, parent.width)
                    }
                }
            }
        }
        QQC2.Button {
            anchors {
                top: parent.top
                right: parent.right
            }
            // Slightly odd check - sometimes this will return a longer string, but as it's a
            // base64 encoding of a midi file, it'll be at least the header size of that if
            // it's useful, so... just check for bigger than 10, that'll do
            visible: waveBar.controlObj != null && waveBar.controlObj.hasOwnProperty("metadata") && waveBar.controlObj.metadata.midiRecording != null && waveBar.controlObj.metadata.midiRecording.length > 10
            text: Zynthbox.MidiRecorder.isPlaying ? "Stop playing midi" : "Play embedded midi"
            onClicked: {
                if (Zynthbox.MidiRecorder.isPlaying) {
                    Zynthbox.MidiRecorder.stopPlayback();
                } else {
                    if (Zynthbox.MidiRecorder.loadFromBase64Midi(waveBar.controlObj.metadata.midiRecording)) {
                        Zynthbox.MidiRecorder.forceToChannel(Zynthbox.PlayGridManager.currentSketchpadTrack);
                        Zynthbox.MidiRecorder.playRecording();
                    } else {
                        console.log("Failed to load recording from clip data, which is:\n", waveBar.controlObj.metadata.midiRecording);
                    }
                }
            }
        }
    }
}

