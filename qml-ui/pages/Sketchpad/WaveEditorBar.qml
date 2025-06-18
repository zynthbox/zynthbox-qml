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
    property QtObject channel: zynqtgui.sketchpad.song != null ? zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId) : null

    property int internalMargin: Kirigami.Units.largeSpacing

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
                bottomStack.slotsBar.channelButton.checked = true
                return true;
            case "KNOB0_TOUCHED":
                if (waveBar.cppClipObject) {
                    if (waveBar.cppClipObject.selectedSliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                        wav.focusSection(waveBar.cppClipObject.selectedSliceObject.startPositionSamples, waveBar.cppClipObject.selectedSliceObject.lengthSamples, 1.0);
                    } else {
                        if (pinchZoomer.scale > 1) {
                            wav.focusPosition(waveBar.cppClipObject.selectedSliceObject.startPositionSamples);
                        }
                    }
                }
                return true;
                break;
            case "KNOB1_TOUCHED":
                if (waveBar.cppClipObject) {
                    if (waveBar.cppClipObject.selectedSliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                        wav.focusSection(waveBar.cppClipObject.selectedSliceObject.startPositionSamples, waveBar.cppClipObject.selectedSliceObject.lengthSamples, 1.0);
                    } else {
                        if (pinchZoomer.scale > 1) {
                            wav.focusPosition(waveBar.cppClipObject.selectedSliceObject.startPositionSamples + waveBar.cppClipObject.selectedSliceObject.loopDeltaSamples);
                        }
                    }
                }
                return true;
                break;
            case "KNOB2_TOUCHED":
                if (waveBar.cppClipObject) {
                    if (waveBar.cppClipObject.selectedSliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                        wav.focusSection(waveBar.cppClipObject.selectedSliceObject.startPositionSamples, waveBar.cppClipObject.selectedSliceObject.lengthSamples, 1.0);
                    } else {
                        if (pinchZoomer.scale > 1) {
                            wav.focusPosition(waveBar.cppClipObject.selectedSliceObject.startPositionSamples + waveBar.cppClipObject.selectedSliceObject.lengthSamples);
                        }
                    }
                }
                return true;
                break;
            case "KNOB3_TOUCHED":
                return true;
            case "KNOB0_UP":
                if (waveBar.cppClipObject && waveBar.cppClipObject.selectedSliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                    if (zynqtgui.modeButtonPressed) {
                        zynqtgui.ignoreNextModeButtonPress = true;
                        waveBar.cppClipObject.selectedSliceObject.startPositionSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.selectedSliceObject.startPositionSamples + 1, 0, waveBar.cppClipObject.durationSamples - waveBar.cppClipObject.selectedSliceObject.lengthSamples);
                    } else {
                        waveBar.cppClipObject.selectedSliceObject.startPositionSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.selectedSliceObject.startPositionSamples + waveBar.cppClipObject.selectedSliceObject.lengthSamples, 0, waveBar.cppClipObject.durationSamples - waveBar.cppClipObject.selectedSliceObject.lengthSamples);
                    }
                    wav.focusSection(waveBar.cppClipObject.selectedSliceObject.startPositionSamples, waveBar.cppClipObject.selectedSliceObject.lengthSamples, 1.0);
                } else {
                    if (zynqtgui.modeButtonPressed) {
                        zynqtgui.ignoreNextModeButtonPress = true;
                        waveBar.cppClipObject.selectedSliceObject.startPositionSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.selectedSliceObject.startPositionSamples + 1, 0, waveBar.cppClipObject.durationSamples);
                    } else {
                        waveBar.cppClipObject.selectedSliceObject.startPositionSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.selectedSliceObject.startPositionSamples + wav.samplesPerPixel, 0, waveBar.cppClipObject.durationSamples);
                    }
                    if (pinchZoomer.scale > 1) {
                        wav.focusPosition(waveBar.cppClipObject.selectedSliceObject.startPositionSamples);
                    }
                }
                return true;
            case "KNOB0_DOWN":
                if (waveBar.cppClipObject && waveBar.cppClipObject.selectedSliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                    if (zynqtgui.modeButtonPressed) {
                        zynqtgui.ignoreNextModeButtonPress = true;
                        waveBar.cppClipObject.selectedSliceObject.startPositionSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.selectedSliceObject.startPositionSamples - 1, 0, waveBar.cppClipObject.durationSamples - waveBar.cppClipObject.selectedSliceObject.lengthSamples);
                    } else {
                        waveBar.cppClipObject.selectedSliceObject.startPositionSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.selectedSliceObject.startPositionSamples - waveBar.cppClipObject.selectedSliceObject.lengthSamples, 0, waveBar.cppClipObject.durationSamples - waveBar.cppClipObject.selectedSliceObject.lengthSamples);
                    }
                    wav.focusSection(waveBar.cppClipObject.selectedSliceObject.startPositionSamples, waveBar.cppClipObject.selectedSliceObject.lengthSamples, 1.0);
                } else {
                    if (zynqtgui.modeButtonPressed) {
                        zynqtgui.ignoreNextModeButtonPress = true;
                        waveBar.cppClipObject.selectedSliceObject.startPositionSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.selectedSliceObject.startPositionSamples - 1, 0, waveBar.cppClipObject.durationSamples);
                    } else {
                        waveBar.cppClipObject.selectedSliceObject.startPositionSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.selectedSliceObject.startPositionSamples - wav.samplesPerPixel, 0, waveBar.cppClipObject.durationSamples);
                    }
                    if (pinchZoomer.scale > 1) {
                        wav.focusPosition(waveBar.cppClipObject.selectedSliceObject.startPositionSamples);
                    }
                }
                return true;
            case "KNOB1_UP":
                if (waveBar.cppClipObject && waveBar.cppClipObject.selectedSliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                    // No loop delta to work on with the wavetable style sounds (it's locked to 0)
                } else {
                    if (waveBar.cppClipObject.snapLengthToBeat) {
                        waveBar.cppClipObject.selectedSliceObject.loopDeltaSeconds = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.selectedSliceObject.loopDeltaSeconds + (60 / waveBar.cppClipObject.bpm), 0, waveBar.cppClipObject.selectedSliceObject.lengthSeconds);
                    } else {
                        if (zynqtgui.modeButtonPressed) {
                            zynqtgui.ignoreNextModeButtonPress = true;
                            waveBar.cppClipObject.selectedSliceObject.loopDeltaSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.selectedSliceObject.loopDeltaSamples + 1, 0, waveBar.cppClipObject.selectedSliceObject.lengthSamples);
                        } else {
                            waveBar.cppClipObject.selectedSliceObject.loopDeltaSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.selectedSliceObject.loopDeltaSamples + wav.samplesPerPixel, 0, waveBar.cppClipObject.selectedSliceObject.lengthSamples);
                        }
                    }
                    if (pinchZoomer.scale > 1) {
                        wav.focusPosition(waveBar.cppClipObject.selectedSliceObject.startPositionSamples + waveBar.cppClipObject.selectedSliceObject.loopDeltaSamples);
                    }
                }
                return true;
            case "KNOB1_DOWN":
                if (waveBar.cppClipObject && waveBar.cppClipObject.selectedSliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                    // No loop delta to work on with the wavetable style sounds (it's locked to 0)
                } else {
                    if (waveBar.cppClipObject.snapLengthToBeat) {
                        waveBar.cppClipObject.selectedSliceObject.loopDeltaSeconds = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.selectedSliceObject.loopDeltaSeconds - (60 / waveBar.cppClipObject.bpm), 0, waveBar.cppClipObject.selectedSliceObject.lengthSeconds);
                    } else {
                        if (zynqtgui.modeButtonPressed) {
                            zynqtgui.ignoreNextModeButtonPress = true;
                            waveBar.cppClipObject.selectedSliceObject.loopDeltaSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.selectedSliceObject.loopDeltaSamples - 1, 0, waveBar.cppClipObject.selectedSliceObject.lengthSamples);
                        } else {
                            waveBar.cppClipObject.selectedSliceObject.loopDeltaSamples = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.selectedSliceObject.loopDeltaSamples - wav.samplesPerPixel, 0, waveBar.cppClipObject.selectedSliceObject.lengthSamples);
                        }
                    }
                    if (pinchZoomer.scale > 1) {
                        wav.focusPosition(waveBar.cppClipObject.selectedSliceObject.startPositionSamples + waveBar.cppClipObject.selectedSliceObject.loopDeltaSamples);
                    }
                }
                return true;
            case "KNOB2_UP":
                if (waveBar.cppClipObject && waveBar.cppClipObject.selectedSliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                    if (zynqtgui.modeButtonPressed) {
                        zynqtgui.ignoreNextModeButtonPress = true;
                        if (waveBar.cppClipObject.selectedSliceObject.lengthSamples < waveBar.cppClipObject.durationSamples) {
                            waveBar.cppClipObject.selectedSliceObject.lengthSamples = waveBar.cppClipObject.selectedSliceObject.lengthSamples + 1;
                        }
                    } else {
                        let currentDivision = Math.round(waveBar.cppClipObject.durationSamples / Math.max(1, waveBar.cppClipObject.selectedSliceObject.lengthSamples));
                        if (currentDivision > 1) {
                            waveBar.cppClipObject.selectedSliceObject.lengthSamples = waveBar.cppClipObject.durationSamples / (currentDivision - 1);
                        }
                    }
                    wav.focusSection(waveBar.cppClipObject.selectedSliceObject.startPositionSamples, waveBar.cppClipObject.selectedSliceObject.lengthSamples, 1.0);
                } else {
                    if (waveBar.cppClipObject.snapLengthToBeat) {
                        waveBar.cppClipObject.selectedSliceObject.lengthBeats = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.selectedSliceObject.lengthBeats + 1, 0, 64);
                    } else {
                        if (zynqtgui.modeButtonPressed) {
                            zynqtgui.ignoreNextModeButtonPress = true;
                            waveBar.cppClipObject.selectedSliceObject.lengthSamples = waveBar.cppClipObject.selectedSliceObject.lengthSamples + 1;
                        } else {
                            waveBar.cppClipObject.selectedSliceObject.lengthSamples = waveBar.cppClipObject.selectedSliceObject.lengthSamples + wav.samplesPerPixel;
                        }
                    }
                    if (pinchZoomer.scale > 1) {
                        wav.focusPosition(waveBar.cppClipObject.selectedSliceObject.startPositionSamples + waveBar.cppClipObject.selectedSliceObject.lengthSamples);
                    }
                }
                return true;
            case "KNOB2_DOWN":
                if (waveBar.cppClipObject && waveBar.cppClipObject.selectedSliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                    if (zynqtgui.modeButtonPressed) {
                        zynqtgui.ignoreNextModeButtonPress = true;
                        if (waveBar.cppClipObject.selectedSliceObject.lengthSamples > 1) {
                            waveBar.cppClipObject.selectedSliceObject.lengthSamples = waveBar.cppClipObject.selectedSliceObject.lengthSamples - 1;
                        }
                    } else {
                        let currentDivision = Math.round(waveBar.cppClipObject.durationSamples / Math.max(1, waveBar.cppClipObject.selectedSliceObject.lengthSamples));
                        if (currentDivision < waveBar.cppClipObject.durationSamples) {
                            waveBar.cppClipObject.selectedSliceObject.lengthSamples = waveBar.cppClipObject.durationSamples / (currentDivision + 1);
                        }
                    }
                    wav.focusSection(waveBar.cppClipObject.selectedSliceObject.startPositionSamples, waveBar.cppClipObject.selectedSliceObject.lengthSamples, 1.0);
                } else {
                    if (waveBar.cppClipObject.snapLengthToBeat) {
                        waveBar.cppClipObject.selectedSliceObject.lengthBeats = Zynthian.CommonUtils.clamp(waveBar.cppClipObject.selectedSliceObject.lengthBeats - 1, 0, 64);
                    } else {
                        if (zynqtgui.modeButtonPressed) {
                            zynqtgui.ignoreNextModeButtonPress = true;
                            waveBar.cppClipObject.selectedSliceObject.lengthSamples = Math.max(0, waveBar.cppClipObject.selectedSliceObject.lengthSamples - 1);
                        } else {
                            waveBar.cppClipObject.selectedSliceObject.lengthSamples = Math.max(0, waveBar.cppClipObject.selectedSliceObject.lengthSamples - wav.samplesPerPixel);
                        }
                    }
                    if (pinchZoomer.scale > 1) {
                        wav.focusPosition(waveBar.cppClipObject.selectedSliceObject.startPositionSamples + waveBar.cppClipObject.selectedSliceObject.lengthSamples);
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

        function focusPosition(positionToFocus) {
            pinchZoomer.position = Math.max(0, Math.min((positionToFocus - (wav.windowSizeSamples * 0.5)) / (waveBar.cppClipObject.durationSamples - wav.windowSizeSamples), 1));
        }
        function focusSection(startPointInSamples, sectionLengthInSamples, windowSize) {
            if (windowSize == undefined) {
                windowSize = 2.0;
            }
            pinchZoomer.scale = (waveBar.cppClipObject.durationSamples) / (sectionLengthInSamples * windowSize);
            focusPosition(startPointInSamples + (sectionLengthInSamples * 0.5));
        }

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: waveBar.internalMargin
        Layout.bottomMargin: pinchZoomer.scale > 1 ? waveBar.internalMargin + waveBar.height * 0.1 : waveBar.internalMargin
        color: Kirigami.Theme.textColor
        Timer {
            id: waveFormThrottle
            interval: 1; running: false; repeat: false;
            onTriggered: {
                wav.source = waveBar.cppClipObject ? "clip:/%1".arg(waveBar.cppClipObject.id) : ""
                if (waveBar.cppClipObject && waveBar.cppClipObject.selectedSliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                    wav.focusSection(waveBar.cppClipObject.selectedSliceObject.startPositionSamples, waveBar.cppClipObject.selectedSliceObject.lengthSamples, 1.0);
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
                        // Don't zoom in if... there's nothing small enough to zoom to
                        if (waveBar.cppClipObject.selectedSliceObject.lengthSamples <= waveBar.cppClipObject.durationSamples / 2) {
                            // Zoom in to fit the current window size (that is, fit twice the size of the window, and then position it in the centre of the viewport)
                            wav.focusSection(waveBar.cppClipObject.selectedSliceObject.startPositionSamples, waveBar.cppClipObject.selectedSliceObject.lengthSamples);
                        }
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
                        pinchMouseArea.initialStartPositionSamples = waveBar.cppClipObject.selectedSliceObject.startPositionSamples;
                        pinchMouseArea.initialLoopDeltaSamples = waveBar.cppClipObject.selectedSliceObject.loopDeltaSamples;
                        pinchMouseArea.initialLoopDelta = waveBar.cppClipObject.selectedSliceObject.loopDeltaSeconds;
                        pinchMouseArea.initialLengthSamples = waveBar.cppClipObject.selectedSliceObject.lengthSamples;
                        pinchMouseArea.initialLengthBeats = waveBar.cppClipObject.selectedSliceObject.lengthBeats;
                    }
                }
                onPositionChanged: {
                    // Don't try and do the setty thing if there's a pinch happening
                    if (pinchZoomer.pinch.active === false && waveBar.cppClipObject) {
                        let deltaX = mouse.x - pinchMouseArea.initialX;
                        if (pressedY < oneThird) {
                            // Upper third (start point)
                            if (waveBar.cppClipObject.selectedSliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                                if (zynqtgui.modeButtonPressed) {
                                    zynqtgui.ignoreNextModeButtonPress = true;
                                    waveBar.cppClipObject.selectedSliceObject.startPositionSamples = Zynthian.CommonUtils.clamp(pinchMouseArea.initialStartPositionSamples + deltaX, 0, waveBar.cppClipObject.durationSamples - waveBar.cppClipObject.selectedSliceObject.lengthSamples);
                                } else {
                                    waveBar.cppClipObject.selectedSliceObject.startPositionSamples = Zynthian.CommonUtils.clamp(pinchMouseArea.initialStartPositionSamples + (Math.round(deltaX / Kirigami.Units.gridUnit) * waveBar.cppClipObject.selectedSliceObject.lengthSamples), 0, waveBar.cppClipObject.durationSamples - waveBar.cppClipObject.selectedSliceObject.lengthSamples);
                                }
                                wav.focusSection(waveBar.cppClipObject.selectedSliceObject.startPositionSamples, waveBar.cppClipObject.selectedSliceObject.lengthSamples, 1.0);
                            } else {
                                if (zynqtgui.modeButtonPressed) {
                                    zynqtgui.ignoreNextModeButtonPress = true;
                                    waveBar.cppClipObject.selectedSliceObject.startPositionSamples = Zynthian.CommonUtils.clamp(pinchMouseArea.initialStartPositionSamples + deltaX, 0, waveBar.cppClipObject.durationSamples);
                                } else {
                                    waveBar.cppClipObject.selectedSliceObject.startPositionSamples = Zynthian.CommonUtils.clamp(pinchMouseArea.initialStartPositionSamples + (deltaX * wav.samplesPerPixel), 0, waveBar.cppClipObject.durationSamples);
                                }
                            }
                        } else if (pressedY < twoThirds) {
                            // Centre third (loop point) - this may need some fanciness going on when we add in loopDelta2
                            if (waveBar.cppClipObject && waveBar.cppClipObject.selectedSliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                                // No loop delta to work on with the wavetable style sounds (it's locked to 0)
                            } else {
                                if (waveBar.cppClipObject.snapLengthToBeat) {
                                    waveBar.cppClipObject.selectedSliceObject.loopDeltaSeconds = Zynthian.CommonUtils.clamp(pinchMouseArea.initialLoopDelta + (Math.round(deltaX / wav.pixelsPerBeat) * wav.pixelsPerBeat * wav.pixelToSecs), 0, waveBar.cppClipObject.selectedSliceObject.lengthSeconds);
                                } else {
                                    if (zynqtgui.modeButtonPressed) {
                                        zynqtgui.ignoreNextModeButtonPress = true;
                                        waveBar.cppClipObject.selectedSliceObject.loopDeltaSamples = Zynthian.CommonUtils.clamp(pinchMouseArea.initialLoopDeltaSamples + deltaX, 0, waveBar.cppClipObject.selectedSliceObject.lengthSamples);
                                    } else {
                                        waveBar.cppClipObject.selectedSliceObject.loopDeltaSamples = Zynthian.CommonUtils.clamp(pinchMouseArea.initialLoopDeltaSamples + (deltaX * wav.samplesPerPixel), 0, waveBar.cppClipObject.selectedSliceObject.lengthSamples);
                                    }
                                }
                            }
                        } else {
                            // Lower third (end point)
                            if (waveBar.cppClipObject && waveBar.cppClipObject.selectedSliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle) {
                                if (zynqtgui.modeButtonPressed) {
                                    zynqtgui.ignoreNextModeButtonPress = true;
                                    waveBar.cppClipObject.selectedSliceObject.lengthSamples = Math.min(pinchMouseArea.initialLengthSamples + deltaX, waveBar.cppClipObject.durationSamples);
                                } else {
                                    let currentDivision = Math.round(waveBar.cppClipObject.durationSamples / Math.max(1, pinchMouseArea.initialLengthSamples));
                                    if (currentDivision > 1) {
                                        waveBar.cppClipObject.selectedSliceObject.lengthSamples = waveBar.cppClipObject.durationSamples / (currentDivision - Math.round(deltaX / Kirigami.Units.gridUnit));
                                    }
                                }
                                wav.focusSection(waveBar.cppClipObject.selectedSliceObject.startPositionSamples, waveBar.cppClipObject.selectedSliceObject.lengthSamples, 1.0);
                            } else {
                                if (waveBar.cppClipObject.snapLengthToBeat) {
                                    waveBar.cppClipObject.selectedSliceObject.lengthBeats = Zynthian.CommonUtils.clamp(pinchMouseArea.initialLengthBeats + Math.round(deltaX / wav.pixelsPerBeat), 0, 64);
                                } else {
                                    if (zynqtgui.modeButtonPressed) {
                                        zynqtgui.ignoreNextModeButtonPress = true;
                                        waveBar.cppClipObject.selectedSliceObject.lengthSamples = Math.max(0, pinchMouseArea.initialLengthSamples + deltaX);
                                    } else {
                                        waveBar.cppClipObject.selectedSliceObject.lengthSamples = Math.max(0, pinchMouseArea.initialLengthSamples + (deltaX * wav.samplesPerPixel));
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
            color: Kirigami.Theme.textColor
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
                    margins: -1
                }
                border {
                    width: 1
                    color: Kirigami.Theme.focusColor
                }
                color: "transparent"
            }
            MouseArea {
                anchors.fill: parent
                readonly property real leftPosition: scrollGrooveLeft.width / width
                readonly property real rightPosition: scrollGrooveRight.x / width
                property int handleIndex: -1
                // -1 is "no handle", just move the position
                // 0 is left handle
                // 1 is right handle
                property real initialStart: 0
                property real initialEnd: 0
                property real initialX: 0
                onPressed: {
                    initialX = mouse.x;
                    initialStart = leftPosition;
                    initialEnd = rightPosition;
                    let relativePressPosition = mouse.x / width;
                    if (relativePressPosition < leftPosition - 0.05 || relativePressPosition > rightPosition + 0.05) {
                        // console.log("Entirely outside the centre area");
                        handleIndex = -1
                    } else if (relativePressPosition < leftPosition + 0.05) {
                        // console.log("Pressing left handle");
                        handleIndex = 0;
                    } else if (relativePressPosition > rightPosition - 0.05) {
                        // console.log("Pressing right handle");
                        handleIndex = 1;
                    } else {
                        // console.log("Pressed between the two handles");
                        handleIndex = -1;
                    }
                }
                onPositionChanged: {
                    let deltaX = mouse.x - initialX;
                    if (handleIndex === 0) {
                        let newStartPosition = waveBar.cppClipObject.durationSamples * (initialStart + (deltaX / width));
                        let newEndPosition = waveBar.cppClipObject.durationSamples * initialEnd
                        wav.focusSection(newStartPosition, newEndPosition - newStartPosition, 1.0);
                    } else if (handleIndex === 1) {
                        let newStartPosition = waveBar.cppClipObject.durationSamples * initialStart;
                        let newEndPosition = waveBar.cppClipObject.durationSamples * (initialEnd + (deltaX / width));
                        wav.focusSection(newStartPosition, newEndPosition - newStartPosition, 1.0);
                    } else {
                        pinchZoomer.position = Math.max(0, Math.min(mouse.x / width, 1));
                    }
                }
            }
        }

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
            visible: waveBar.cppClipObject && waveBar.cppClipObject.selectedSliceObject.effectivePlaybackStyle != Zynthbox.ClipAudioSource.WavetableStyle
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
                font.pointSize: waveBar.cppClipObject && waveBar.cppClipObject.selectedSliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle ? Kirigami.Theme.defaultFont.pointSize * 0.8 : Kirigami.Theme.defaultFont.pointSize * 1.2
                anchors {
                    top: parent.top
                    right: parent.right
                    bottom: parent.bottom
                    margins: Kirigami.Units.largeSpacing * 1.5
                }
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                property double currentDivision: waveBar.cppClipObject && waveBar.cppClipObject.selectedSliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle ? Math.round(waveBar.cppClipObject.durationSamples / Math.max(1, waveBar.cppClipObject.selectedSliceObject.lengthSamples)) : 1
                text: waveBar.cppClipObject
                    ? waveBar.cppClipObject.selectedSliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle
                        ? "1/%1".arg(Number.isInteger(currentDivision) ? currentDivision : currentDivision.toFixed(2))
                        : qsTr("%1:%2 E", "End")
                            .arg(Math.floor(waveBar.cppClipObject.selectedSliceObject.lengthBeats / 4))
                            .arg((waveBar.cppClipObject.selectedSliceObject.lengthBeats % 4).toFixed(waveBar.cppClipObject.snapLengthToBeat ? 0 : 2))
                    : ""
            }
            Text {
                visible: waveBar.cppClipObject && waveBar.cppClipObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                color: Kirigami.Theme.textColor
                font.pointSize: waveBar.cppClipObject && waveBar.cppClipObject.selectedSliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle ? Kirigami.Theme.defaultFont.pointSize * 0.8 : Kirigami.Theme.defaultFont.pointSize * 1.2
                anchors {
                    right: parent.right
                    bottom: parent.top
                    margins: Kirigami.Units.largeSpacing * 1.5
                    bottomMargin: parent.height // To anchors the thing to the top of the parent's container...
                }
                height: parent.height
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                text: visible
                    ? qsTr("%1\nsamples").arg(waveBar.cppClipObject.selectedSliceObject.lengthSamples)
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
                ? waveBar.cppClipObject.selectedSliceObject.startPositionSamples / waveBar.cppClipObject.durationSamples
                : 1
            x: waveBar.cppClipObject
                ? Zynthian.CommonUtils.fitInWindow(startPositionRelative, wav.relativeStart, wav.relativeEnd) * parent.width
                : 0
        }

        // Loop line
        Rectangle {
            id: loopLine
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            color: Kirigami.Theme.highlightColor
            opacity: 0.6
            width: startLoopLine.width
            property real loopDeltaRelative: waveBar.cppClipObject
                ? waveBar.cppClipObject.selectedSliceObject.loopDeltaSamples / waveBar.cppClipObject.durationSamples
                : 0
            x: waveBar.cppClipObject
                ? Zynthian.CommonUtils.fitInWindow(startLoopLine.startPositionRelative + loopDeltaRelative, wav.relativeStart, wav.relativeEnd) * parent.width
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
                ? Zynthian.CommonUtils.fitInWindow(startLoopLine.startPositionRelative + (waveBar.cppClipObject.selectedSliceObject.lengthSamples / waveBar.cppClipObject.durationSamples), wav.relativeStart, wav.relativeEnd) * parent.width
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
            x: visible ? Zynthian.CommonUtils.fitInWindow(waveBar.cppClipObject.position, wav.relativeStart, wav.relativeEnd) * parent.width : 0
        }

        // SamplerSynth progress dots
        Timer {
            id: dotFetcher
            interval: 1; repeat: false; running: false;
            onTriggered: {
                progressDots.playbackPositions = waveBar.visible && (waveBar.channel.trackType === "synth") && waveBar.cppClipObject
                    ? waveBar.cppClipObject.playbackPositions
                    : null
            }
        }
        Connections {
            target: waveBar
            onVisibleChanged: dotFetcher.restart();
            onCppClipObjectChanged: dotFetcher.restart();
        }
        Connections {
            target: waveBar.channel
            onTrack_type_changed: dotFetcher.restart();
        }
        Repeater {
            id: progressDots
            model: Zynthbox.Plugin.clipMaximumPositionCount
            property QtObject playbackPositions: null
            delegate: Item {
                property QtObject progressEntry: progressDots.playbackPositions ? progressDots.playbackPositions.positions[model.index] : null
                visible: progressEntry && progressEntry.id > -1
                Rectangle {
                    anchors.centerIn: parent
                    rotation: 45
                    color: Kirigami.Theme.highlightColor
                    width: Kirigami.Units.largeSpacing
                    height:  Kirigami.Units.largeSpacing
                    scale: progressEntry ? 0.5 + progressEntry.gain : 1
                }
                anchors {
                    top: parent.verticalCenter
                    topMargin: progressEntry ? progressEntry.pan * (parent.height / 2) : 0
                }
                x: visible ? Zynthian.CommonUtils.fitInWindow(progressEntry.progress, wav.relativeStart, wav.relativeEnd) * parent.width : 0
            }
        }

        // Create and place beat lines
        Repeater {
            // Count number of beat lines to be shown as per beat and visible width
            model: Math.ceil(wav.width / wav.pixelsPerBeat)
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

