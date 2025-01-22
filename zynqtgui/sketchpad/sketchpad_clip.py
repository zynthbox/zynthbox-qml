#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Sketchpad Clip: An object to store clip information for a channel
#
# Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
#
# ******************************************************************************
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# For a full copy of the GNU General Public License see the LICENSE.txt file.
#
# ******************************************************************************
import math
import re
import shutil
import tempfile
import traceback
import taglib
import ujson as json
import os
import logging
import Zynthbox
import numpy as np

from pathlib import Path
from subprocess import check_output
from PySide2.QtCore import Property, QObject, QTimer, Qt, Signal, Slot
from zynqtgui import zynthian_gui_config

def restoreEqualiserAndCompressorSettings(equaliserCompressorObject, dataChunk):
    for index, filterValues in enumerate(dataChunk["equaliserSettings"]):
        equaliserCompressorObject.equaliserSettings()[index].setFilterType(Zynthbox.JackPassthroughFilter.FilterType.values[filterValues["filterType"]])
        equaliserCompressorObject.equaliserSettings()[index].setFrequency(filterValues["frequency"])
        equaliserCompressorObject.equaliserSettings()[index].setQuality(filterValues["quality"])
        equaliserCompressorObject.equaliserSettings()[index].setSoloed(filterValues["soloed"])
        equaliserCompressorObject.equaliserSettings()[index].setGain(filterValues["gain"])
        equaliserCompressorObject.equaliserSettings()[index].setActive(filterValues["active"])
    equaliserCompressorObject.compressorSettings().setThresholdDB(dataChunk["compressorSettings"]["thresholdDB"])
    equaliserCompressorObject.compressorSettings().setMakeUpGainDB(dataChunk["compressorSettings"]["makeUpGainDB"])
    equaliserCompressorObject.compressorSettings().setKneeWidthDB(dataChunk["compressorSettings"]["kneeWidthDB"])
    equaliserCompressorObject.compressorSettings().setRelease(dataChunk["compressorSettings"]["release"])
    equaliserCompressorObject.compressorSettings().setAttack(dataChunk["compressorSettings"]["attack"])
    equaliserCompressorObject.compressorSettings().setRatio(dataChunk["compressorSettings"]["ratio"])
    equaliserCompressorObject.setEqualiserEnabled(dataChunk["equaliserEnabled"])
    equaliserCompressorObject.setCompressorEnabled(dataChunk["compressorEnabled"])
    equaliserCompressorObject.setCompressorSidechannelLeft(dataChunk["compressorSidechannelLeft"])
    equaliserCompressorObject.setCompressorSidechannelRight(dataChunk["compressorSidechannelRight"])
def setEqualiserAndCompressorDefaults(equaliserCompressorObject):
    equaliserCompressorObject.setEqualiserEnabled(False)
    equaliserCompressorObject.setCompressorEnabled(False)
    equaliserCompressorObject.setCompressorSidechannelLeft("")
    equaliserCompressorObject.setCompressorSidechannelRight("")
    for filterObject in equaliserCompressorObject.equaliserSettings():
        filterObject.setDefaults()
    equaliserCompressorObject.compressorSettings().setDefaults()
def serializeEqualiserAndCompressorSettings(equaliserCompressorObject):
    equaliserSettingsData = []
    for client in equaliserCompressorObject.equaliserSettings():
        equaliserSettingsData.append({
            "filterType": client.filterType().name.decode().split(".")[-1],
            "frequency": client.frequency(),
            "quality": client.quality(),
            "soloed": client.soloed(),
            "gain": client.gain(),
            "active": client.active()
        })
    return {
        "equaliserSettings": equaliserSettingsData,
        "equaliserEnabled": equaliserCompressorObject.equaliserEnabled(),
        "compressorEnabled": equaliserCompressorObject.compressorEnabled(),
        "compressorSidechannelLeft": equaliserCompressorObject.compressorSidechannelLeft(),
        "compressorSidechannelRight": equaliserCompressorObject.compressorSidechannelRight(),
        "compressorSettings": {
            "thresholdDB": equaliserCompressorObject.compressorSettings().thresholdDB(),
            "makeUpGainDB": equaliserCompressorObject.compressorSettings().makeUpGainDB(),
            "kneeWidthDB": equaliserCompressorObject.compressorSettings().kneeWidthDB(),
            "release": equaliserCompressorObject.compressorSettings().release(),
            "attack": equaliserCompressorObject.compressorSettings().attack(),
            "ratio": equaliserCompressorObject.compressorSettings().ratio()
        }
    }


class sketchpad_clip_metadata(QObject):
    def __init__(self, clip):
        super(sketchpad_clip_metadata, self).__init__(clip)

        self.clip = clip
        self.__audioMetadata = None
        self.__isReading = False
        self.__isWriting = False
        self.writeTimer = QTimer(self)
        self.writeTimer.setInterval(1000)
        self.writeTimer.setSingleShot(True)
        self.writeTimer.timeout.connect(self.write)

        # Sound metadata
        self.__audioType = None
        self.__audioTypeSettings = None
        self.__midiRecording = None
        self.__patternJson = None
        self.__routingStyle = None
        self.__samplePickingStyle = None
        self.__samples = None
        self.__soundSnapshot = None

    def get_audioType(self): return self.__audioType
    def get_audioTypeSettings(self): return self.__audioTypeSettings
    def get_midiRecording(self): return self.__midiRecording
    def get_patternJson(self): return self.__patternJson
    def get_routingStyle(self): return self.__routingStyle
    def get_samplePickingStyle(self): return self.__samplePickingStyle
    def get_samples(self): return self.__samples
    def get_soundSnapshot(self): return self.__soundSnapshot

    def set_audioType(self, value, write=True, force=False):
        if value != self.__audioType or force:
            self.__audioType = value
            self.audioTypeChanged.emit()
            if write:
                self.scheduleWrite()
    def set_audioTypeSettings(self, value, write=True, force=False):
        if value != self.__audioTypeSettings or force:
            self.__audioTypeSettings = value
            self.audioTypeSettingsChanged.emit()
            if write:
                self.scheduleWrite()
    def set_midiRecording(self, value, write=True, force=False):
        if value != self.__midiRecording or force:
            self.__midiRecording = value
            self.midiRecordingChanged.emit()
            if write:
                self.scheduleWrite()
    def set_patternJson(self, value, write=True, force=False):
        if value != self.__patternJson or force:
            self.__patternJson = value
            self.patternJsonChanged.emit()
            if write:
                self.scheduleWrite()
    def set_routingStyle(self, value, write=True, force=False):
        if value != self.__routingStyle or force:
            self.__routingStyle = value
            self.routingStyleChanged.emit()
            if write:
                self.scheduleWrite()
    def set_samplePickingStyle(self, value, write=True, force=False):
        if value != self.__samplePickingStyle or force:
            self.__samplePickingStyle = value
            self.samplePickingStyleChanged.emit()
            if write:
                self.scheduleWrite()
    def set_samples(self, value, write=True, force=False):
        if value != self.__samples or force:
            self.__samples = value
            self.samplesChanged.emit()
            if write:
                self.scheduleWrite()
    def set_soundSnapshot(self, value, write=True, force=False):
        if value != self.__soundSnapshot or force:
            self.__soundSnapshot = value
            self.soundSnapshotChanged.emit()
            if write:
                self.scheduleWrite()

    def set_timeStretchStyle(self, value, sliceIndex):
        if self.clip.audioSource is not None:
            sliceSettingsObject = self.clip.audioSource.sliceFromIndex(sliceIndex)
            timeStretchStyle = value
            if timeStretchStyle.startswith("Zynthbox.ClipAudioSource.TimeStretchStyle."):
                timeStretchStyle = timeStretchStyle.split(".")[-1]
            if timeStretchStyle in Zynthbox.ClipAudioSource.TimeStretchStyle.values:
                sliceSettingsObject.setTimeStretchStyle(Zynthbox.ClipAudioSource.TimeStretchStyle.values[timeStretchStyle])
            else:
                if self.clip.is_channel_sample == False:
                    # If we are using this as a Sketch, we should be time-stretching things like pitch shifts by default
                    sliceSettingsObject.setTimeStretchStyle(Zynthbox.ClipAudioSource.TimeStretchStyle.TimeStretchBetter)
                else:
                    sliceSettingsObject.setTimeStretchStyle(Zynthbox.ClipAudioSource.TimeStretchStyle.TimeStretchOff)
    def set_playbackStyle(self, value, sliceIndex):
        if self.clip.audioSource is not None:
            sliceSettingsObject = self.clip.audioSource.sliceFromIndex(sliceIndex)
            playbackStyle = value
            if playbackStyle.startswith("Zynthbox.ClipAudioSource.PlaybackStyle."):
                playbackStyle = playbackStyle.split(".")[-1]
            if playbackStyle in Zynthbox.ClipAudioSource.PlaybackStyle.values:
                sliceSettingsObject.setPlaybackStyle(Zynthbox.ClipAudioSource.PlaybackStyle.values[playbackStyle])
            else:
                sliceSettingsObject.setPlaybackStyle(Zynthbox.ClipAudioSource.PlaybackStyle.LoopingPlaybackStyle)
    def set_loopStartCrossfadeDirection(self, value, sliceIndex):
        if self.clip.audioSource is not None:
            sliceSettingsObject = self.clip.audioSource.sliceFromIndex(sliceIndex)
            loopStartCrossfadeDirection = value
            if loopStartCrossfadeDirection.startswith("Zynthbox.ClipAudioSource.CrossfadingDirection."):
                loopStartCrossfadeDirection = loopStartCrossfadeDirection.split(".")[-1]
            if loopStartCrossfadeDirection in Zynthbox.ClipAudioSource.CrossfadingDirection.values:
                sliceSettingsObject.setLoopStartCrossfadeDirection(Zynthbox.ClipAudioSource.CrossfadingDirection.values[loopStartCrossfadeDirection])
            else:
                sliceSettingsObject.loopStartCrossfadeDirection(Zynthbox.ClipAudioSource.CrossfadingDirection.CrossfadeOutie)
    def set_stopCrossfadeDirection(self, value, sliceIndex):
        if self.clip.audioSource is not None:
            sliceSettingsObject = self.clip.audioSource.sliceFromIndex(sliceIndex)
            stopCrossfadeDirection = value
            if stopCrossfadeDirection.startswith("Zynthbox.ClipAudioSource.CrossfadingDirection."):
                stopCrossfadeDirection = stopCrossfadeDirection.split(".")[-1]
            if stopCrossfadeDirection in Zynthbox.ClipAudioSource.CrossfadingDirection.values:
                sliceSettingsObject.setStopCrossfadeDirection(Zynthbox.ClipAudioSource.CrossfadingDirection.values[stopCrossfadeDirection])
            else:
                sliceSettingsObject.setStopCrossfadeDirection(Zynthbox.ClipAudioSource.CrossfadingDirection.CrossfadeInnie)
    def set_equaliserSettings(self, value):
        if self.clip.audioSource is not None:
            if value is None or value == "":
                setEqualiserAndCompressorDefaults(self.clip.audioSource)
            else:
                # This really shouldn't happen in the general case, but... occasionally we might have something weird in that json data, and it's just nicer to not crash quite so hard when that happens
                try:
                    restoreEqualiserAndCompressorSettings(self.clip.audioSource, json.loads(value))
                except:
                    logging.error(f"Failed to restore (and so restoring to defaults) the equaliser/compressor settings for {self.clip} from the data: {value}")
                    setEqualiserAndCompressorDefaults(self.clip.audioSource)
    def set_sliceSettings(self, value):
        if self.clip.audioSource is not None:
            if value is None or value == "":
                self.setSliceDefaults()
            else:
                try:
                    self.restoreSliceData(json.loads(value))
                except Exception as e:
                    logging.error(f"Exception {e}\nFailed to restore (and so restoring to defaults) the slice settings for {self.clip} from the data: {value}")
                    self.setSliceDefaults()

    audioTypeChanged = Signal()
    audioTypeSettingsChanged = Signal()
    midiRecordingChanged = Signal()
    patternJsonChanged = Signal()
    routingStyleChanged = Signal()
    samplePickingStyleChanged = Signal()
    samplesChanged = Signal()
    soundSnapshotChanged = Signal()

    audioType = Property(str, get_audioType, set_audioType, notify=audioTypeChanged)
    audioTypeSettings = Property(str, get_audioTypeSettings, set_audioTypeSettings, notify=audioTypeSettingsChanged)
    midiRecording = Property(str, get_midiRecording, set_midiRecording, notify=midiRecordingChanged)
    patternJson = Property(str, get_patternJson, set_patternJson, notify=patternJsonChanged)
    routingStyle = Property(str, get_routingStyle, set_routingStyle, notify=routingStyleChanged)
    samplePickingStyle = Property(str, get_samplePickingStyle, set_samplePickingStyle, notify=samplePickingStyleChanged)
    samples = Property(str, get_samples, set_samples, notify=samplesChanged)
    soundSnapshot = Property(str, get_soundSnapshot, set_soundSnapshot, notify=soundSnapshotChanged)

    def getMetadataProperty(self, name, default=None):
        try:
            value = self.__audioMetadata[name][0]
            if value == "None":
                # If 'None' value is saved, return default
                return default
            return value
        except:
            return default

    # This hooks up the clip's current ClipAudioSource
    def hook(self):
        if self.clip.audioSource:
            def connectEqualiserAndCompressorForSaving(equaliserCompressorObject):
                equaliserCompressorObject.equaliserEnabledChanged.connect(self.scheduleWrite)
                for filterObject in equaliserCompressorObject.equaliserSettings():
                    filterObject.filterTypeChanged.connect(self.scheduleWrite)
                    filterObject.frequencyChanged.connect(self.scheduleWrite)
                    filterObject.qualityChanged.connect(self.scheduleWrite)
                    filterObject.soloedChanged.connect(self.scheduleWrite)
                    filterObject.gainChanged.connect(self.scheduleWrite)
                    filterObject.activeChanged.connect(self.scheduleWrite)
                equaliserCompressorObject.compressorEnabledChanged.connect(self.scheduleWrite)
                equaliserCompressorObject.compressorSidechannelLeftChanged.connect(self.scheduleWrite)
                equaliserCompressorObject.compressorSidechannelRightChanged.connect(self.scheduleWrite)
                equaliserCompressorObject.compressorSettings().thresholdChanged.connect(self.scheduleWrite)
                equaliserCompressorObject.compressorSettings().makeUpGainChanged.connect(self.scheduleWrite)
                equaliserCompressorObject.compressorSettings().kneeWidthChanged.connect(self.scheduleWrite)
                equaliserCompressorObject.compressorSettings().releaseChanged.connect(self.scheduleWrite)
                equaliserCompressorObject.compressorSettings().attackChanged.connect(self.scheduleWrite)
                equaliserCompressorObject.compressorSettings().ratioChanged.connect(self.scheduleWrite)
            connectEqualiserAndCompressorForSaving(self.clip.audioSource)
            self.clip.audioSource.bpmChanged.connect(self.scheduleWrite)
            self.clip.audioSource.autoSynchroniseSpeedRatioChanged.connect(self.scheduleWrite)
            self.clip.audioSource.speedRatioChanged.connect(self.scheduleWrite)
            self.clip.audioSource.sliceCountChanged.connect(self.scheduleWrite)
            self.clip.audioSource.slicesContiguousChanged.connect(self.scheduleWrite)
            def connectSliceForSaving(sliceSettingsObject):
                sliceSettingsObject.subvoiceCountChanged.connect(self.scheduleWrite)
                for subvoiceSettingsObject in sliceSettingsObject.subvoiceSettings():
                    subvoiceSettingsObject.panChanged.connect(self.scheduleWrite)
                    subvoiceSettingsObject.pitchChanged.connect(self.scheduleWrite)
                    subvoiceSettingsObject.gainChanged.connect(self.scheduleWrite)
                sliceSettingsObject.gainHandler().gainChanged.connect(self.scheduleWrite)
                sliceSettingsObject.gainHandler().gainChanged.connect(self.handleGainChanged)
                sliceSettingsObject.playbackStyleChanged.connect(self.scheduleWrite)
                sliceSettingsObject.timeStretchStyleChanged.connect(self.scheduleWrite)
                sliceSettingsObject.pitchChanged.connect(self.scheduleWrite)
                sliceSettingsObject.startPositionChanged.connect(self.scheduleWrite)
                sliceSettingsObject.snapLengthToBeatChanged.connect(self.scheduleWrite)
                sliceSettingsObject.lengthChanged.connect(self.scheduleWrite)
                sliceSettingsObject.loopDeltaChanged.connect(self.scheduleWrite)
                sliceSettingsObject.loopDelta2Changed.connect(self.scheduleWrite)
                sliceSettingsObject.loopCrossfadeAmountChanged.connect(self.scheduleWrite)
                sliceSettingsObject.loopStartCrossfadeDirectionChanged.connect(self.scheduleWrite)
                sliceSettingsObject.stopCrossfadeDirectionChanged.connect(self.scheduleWrite)
                sliceSettingsObject.rootNoteChanged.connect(self.scheduleWrite)
                sliceSettingsObject.keyZoneStartChanged.connect(self.scheduleWrite)
                sliceSettingsObject.keyZoneEndChanged.connect(self.scheduleWrite)
                sliceSettingsObject.velocityMinimumChanged.connect(self.scheduleWrite)
                sliceSettingsObject.velocityMaximumChanged.connect(self.scheduleWrite)
                sliceSettingsObject.panChanged.connect(self.scheduleWrite)
                sliceSettingsObject.adsrParametersChanged.connect(self.scheduleWrite)
                sliceSettingsObject.grainPositionChanged.connect(self.scheduleWrite)
                sliceSettingsObject.grainSprayChanged.connect(self.scheduleWrite)
                sliceSettingsObject.grainScanChanged.connect(self.scheduleWrite)
                sliceSettingsObject.grainIntervalChanged.connect(self.scheduleWrite)
                sliceSettingsObject.grainIntervalAdditionalChanged.connect(self.scheduleWrite)
                sliceSettingsObject.grainSizeChanged.connect(self.scheduleWrite)
                sliceSettingsObject.grainSizeAdditionalChanged.connect(self.scheduleWrite)
                sliceSettingsObject.grainPanMinimumChanged.connect(self.scheduleWrite)
                sliceSettingsObject.grainPanMaximumChanged.connect(self.scheduleWrite)
                sliceSettingsObject.grainPitchMinimum1Changed.connect(self.scheduleWrite)
                sliceSettingsObject.grainPitchMaximum1Changed.connect(self.scheduleWrite)
                sliceSettingsObject.grainPitchMinimum2Changed.connect(self.scheduleWrite)
                sliceSettingsObject.grainPitchMaximum2Changed.connect(self.scheduleWrite)
                sliceSettingsObject.grainPitchPriorityChanged.connect(self.scheduleWrite)
                sliceSettingsObject.grainSustainChanged.connect(self.scheduleWrite)
                sliceSettingsObject.grainTiltChanged.connect(self.scheduleWrite)
                sliceSettingsObject.panChanged.connect(self.handlePanChanged)
            connectSliceForSaving(self.clip.audioSource.rootSlice())
            for sliceObject in self.clip.audioSource.sliceSettings():
                connectSliceForSaving(sliceObject)

    @Slot()
    def handleGainChanged(self):
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_CLIP_GAIN", -1, Zynthbox.ZynthboxBasics.Track(self.clip.channel.id), Zynthbox.ZynthboxBasics.Slot(self.clip.__id__), np.interp(self.clip.audioSource.rootSlice().gainHandler().gainAbsolute(), (0, 1), (0, 127)))

    @Slot()
    def handlePanChanged(self):
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_CLIP_PAN", -1, Zynthbox.ZynthboxBasics.Track(self.clip.channel.id), Zynthbox.ZynthboxBasics.Slot(self.clip.__id__), np.interp(self.clip.audioSource.rootSlice().pan(), (0, 1), (0, 127)))

    # This disconnects all our watcher signals from the clip's current ClipAudioSource instance, if there is one
    def unhook(self):
        if self.clip.audioSource:
            try:
                self.clip.audioSource.disconnect(self)
                for filterObject in self.clip.audioSource.equaliserSettings():
                    filterObject.disconnect(self)
                self.clip.audioSource.compressorSettings().disconnect(self)
                self.clip.audioSource.rootSlice().disconnect(self)
                for subvoiceSettingsObject in self.clip.audioSource.rootSlice().subvoiceSettings():
                    subvoiceSettingsObject.disconnect(self)
                for sliceSettingsObject in self.clip.audioSource.sliceSettings():
                    for subvoiceSettingsObject in sliceSettingsObject.subvoiceSettings():
                        subvoiceSettingsObject.disconnect(self)
                    sliceSettingsObject.disconnect(self)
            except: pass

    def restoreSliceData(self, dataChunk):
        for index, sliceValues in enumerate(dataChunk["settings"]):
            sliceSettingsObject = self.clip.audioSource.sliceFromIndex(index)
            sliceSettingsObject.setPan(sliceValues["pan"])
            sliceSettingsObject.setPitch(sliceValues["pitch"])
            sliceSettingsObject.gainHandler().setGainAbsolute(sliceValues["gain"])
            sliceSettingsObject.setRootNote(sliceValues["rootNote"])
            sliceSettingsObject.setKeyZoneStart(sliceValues["keyZoneStart"])
            sliceSettingsObject.setKeyZoneEnd(sliceValues["keyZoneEnd"])
            sliceSettingsObject.setVelocityMinimum(sliceValues["velocityMinimum"])
            sliceSettingsObject.setVelocityMaximum(sliceValues["velocityMaximum"])
            sliceSettingsObject.setADSRAttack(sliceValues["adsrAttack"])
            sliceSettingsObject.setADSRDecay(sliceValues["adsrDecay"])
            sliceSettingsObject.setADSRSustain(sliceValues["adsrSustain"])
            sliceSettingsObject.setADSRRelease(sliceValues["adsrRelease"])
            sliceSettingsObject.setGrainInterval(sliceValues["grainInterval"])
            sliceSettingsObject.setGrainIntervalAdditional(sliceValues["grainIntervalAdditional"])
            sliceSettingsObject.setGrainPanMaximum(sliceValues["grainPanMaximum"])
            sliceSettingsObject.setGrainPanMinimum(sliceValues["grainPanMinimum"])
            sliceSettingsObject.setGrainPitchMaximum1(sliceValues["grainPitchMaximum1"])
            sliceSettingsObject.setGrainPitchMaximum2(sliceValues["grainPitchMaximum2"])
            sliceSettingsObject.setGrainPitchMinimum1(sliceValues["grainPitchMinimum1"])
            sliceSettingsObject.setGrainPitchMinimum2(sliceValues["grainPitchMinimum2"])
            sliceSettingsObject.setGrainPitchPriority(sliceValues["grainPitchPriority"])
            sliceSettingsObject.setGrainPosition(sliceValues["grainPosition"])
            sliceSettingsObject.setGrainScan(sliceValues["grainScan"])
            sliceSettingsObject.setGrainSize(sliceValues["grainSize"])
            sliceSettingsObject.setGrainSizeAdditional(sliceValues["grainSizeAdditional"])
            sliceSettingsObject.setGrainSpray(sliceValues["grainSpray"])
            sliceSettingsObject.setGrainSustain(sliceValues["grainSustain"])
            sliceSettingsObject.setGrainTilt(sliceValues["grainTilt"])
            self.set_timeStretchStyle(sliceValues["timeStretchStyle"], index)
            self.set_playbackStyle(sliceValues["playbackStyle"], index)
            sliceSettingsObject.setLoopCrossfadeAmount(sliceValues["loopCrossfadeAmount"])
            self.set_loopStartCrossfadeDirection(sliceValues["loopStartCrossfadeDirection"], index)
            self.set_stopCrossfadeDirection(sliceValues["stopCrossfadeDirection"], index)
            sliceSettingsObject.setStartPositionSamples(sliceValues["startPositionSamples"])
            sliceSettingsObject.setLengthSamples(sliceValues["lengthSamples"])
            sliceSettingsObject.setLoopDeltaSamples(sliceValues["loopDeltaSamples"])
            sliceSettingsObject.setLoopDelta2Samples(sliceValues["loopDelta2Samples"])
            if "subvoices" in sliceValues:
                for index, subvoiceValues in enumerate(sliceValues["subvoices"]):
                    sliceSettingsObject.subvoiceSettings()[index].setPan(subvoiceValues["pan"])
                    sliceSettingsObject.subvoiceSettings()[index].setPitch(subvoiceValues["pitch"])
                    sliceSettingsObject.subvoiceSettings()[index].setGain(subvoiceValues["gain"])
                sliceSettingsObject.setSubvoiceCount(sliceValues["subvoiceCount"])
        self.clip.audioSource.setSliceCount(dataChunk["count"])
        if "contiguous" in dataChunk:
            self.clip.audioSource.setSlicesContiguous(dataChunk["contiguous"])
    def setSliceDefaults(self):
        for sliceIndex, sliceSettingsObject in enumerate(self.clip.audioSource.sliceSettings()):
            sliceSettingsObject.setPan(0)
            sliceSettingsObject.setPitch(0)
            sliceSettingsObject.gainHandler().setGainAbsolute(1)
            sliceSettingsObject.setRootNote(60)
            sliceSettingsObject.setKeyZoneStart(0)
            sliceSettingsObject.setKeyZoneEnd(127)
            sliceSettingsObject.setVelocityMinimum(1);
            sliceSettingsObject.setVelocityMaximum(127);
            sliceSettingsObject.setADSRAttack(0)
            sliceSettingsObject.setADSRDecay(0)
            sliceSettingsObject.setADSRSustain(1)
            sliceSettingsObject.setADSRRelease(0)
            sliceSettingsObject.setGrainInterval(10)
            sliceSettingsObject.setGrainIntervalAdditional(10)
            sliceSettingsObject.setGrainPanMinimum(-1)
            sliceSettingsObject.setGrainPanMaximum(1)
            sliceSettingsObject.setGrainPitchMaximum1(1)
            sliceSettingsObject.setGrainPitchMaximum2(1)
            sliceSettingsObject.setGrainPitchMinimum1(1)
            sliceSettingsObject.setGrainPitchMinimum2(1)
            sliceSettingsObject.setGrainPitchPriority(0.5)
            sliceSettingsObject.setGrainPosition(0)
            sliceSettingsObject.setGrainScan(0)
            sliceSettingsObject.setGrainSize(100)
            sliceSettingsObject.setGrainSizeAdditional(10)
            sliceSettingsObject.setGrainSpray(1)
            sliceSettingsObject.setGrainSustain(0.3)
            sliceSettingsObject.setGrainTilt(0.5)
            self.set_timeStretchStyle("TimeStretchOff", sliceIndex)
            self.set_playbackStyle("NonLoopingPlaybackStyle", sliceIndex)
            sliceSettingsObject.setLoopCrossfadeAmount(0)
            self.set_loopStartCrossfadeDirection("CrossfadeOutie", sliceIndex)
            self.set_stopCrossfadeDirection("CrossfadeInnie", sliceIndex)
            sliceSettingsObject.setStartPositionSamples(0)
            sliceSettingsObject.setLengthSamples(0)
            sliceSettingsObject.setLoopDeltaSamples(0)
            sliceSettingsObject.setLoopDelta2Samples(0)
            for subvoiceSettingsObject in sliceSettingsObject.subvoiceSettings():
                subvoiceSettingsObject.setPan(0)
                subvoiceSettingsObject.setPitch(0)
                subvoiceSettingsObject.setGain(1)
            sliceSettingsObject.setSubvoiceCount(0)
        self.clip.audioSource.setSliceCount(0)
        self.clip.audioSource.setSlicesContiguous(False)
    def serializeSliceSettings(self):
        sliceSettingsData = []
        for sliceSettingsObject in self.clip.audioSource.sliceSettings():
            subvoiceSettingsData = []
            for subvoiceSettingsObject in sliceSettingsObject.subvoiceSettings():
                subvoiceSettingsData.append({
                    "pan": subvoiceSettingsObject.pan(),
                    "pitch": subvoiceSettingsObject.pitch(),
                    "gain": subvoiceSettingsObject.gain()
                })
            sliceSettingsData.append({
                "pan": sliceSettingsObject.pan(),
                "pitch": sliceSettingsObject.pitch(),
                "gain": sliceSettingsObject.gainHandler().gainAbsolute(),
                "rootNote": sliceSettingsObject.rootNote(),
                "keyZoneStart": sliceSettingsObject.keyZoneStart(),
                "keyZoneEnd": sliceSettingsObject.keyZoneEnd(),
                "velocityMinimum": sliceSettingsObject.velocityMinimum(),
                "velocityMaximum": sliceSettingsObject.velocityMaximum(),
                "adsrAttack": sliceSettingsObject.adsrAttack(),
                "adsrDecay": sliceSettingsObject.adsrDecay(),
                "adsrSustain": sliceSettingsObject.adsrSustain(),
                "adsrRelease": sliceSettingsObject.adsrRelease(),
                "grainInterval": sliceSettingsObject.grainInterval(),
                "grainIntervalAdditional": sliceSettingsObject.grainIntervalAdditional(),
                "grainPanMaximum": sliceSettingsObject.grainPanMaximum(),
                "grainPanMinimum": sliceSettingsObject.grainPanMinimum(),
                "grainPitchMaximum1": sliceSettingsObject.grainPitchMaximum1(),
                "grainPitchMaximum2": sliceSettingsObject.grainPitchMaximum2(),
                "grainPitchMinimum1": sliceSettingsObject.grainPitchMinimum1(),
                "grainPitchMinimum2": sliceSettingsObject.grainPitchMinimum2(),
                "grainPitchPriority": sliceSettingsObject.grainPitchPriority(),
                "grainPosition": sliceSettingsObject.grainPosition(),
                "grainScan": sliceSettingsObject.grainScan(),
                "grainSize": sliceSettingsObject.grainSize(),
                "grainSizeAdditional": sliceSettingsObject.grainSizeAdditional(),
                "grainSpray": sliceSettingsObject.grainSpray(),
                "grainSustain": sliceSettingsObject.grainSustain(),
                "grainTilt": sliceSettingsObject.grainTilt(),
                "timeStretchStyle": str(sliceSettingsObject.timeStretchStyle()).split(".")[-1],
                "playbackStyle": str(sliceSettingsObject.playbackStyle()).split(".")[-1],
                "loopCrossfadeAmount": sliceSettingsObject.loopCrossfadeAmount(),
                "loopStartCrossfadeDirection": str(sliceSettingsObject.loopStartCrossfadeDirection()).split(".")[-1],
                "stopCrossfadeDirection": str(sliceSettingsObject.stopCrossfadeDirection()).split(".")[-1],
                "startPositionSamples": sliceSettingsObject.startPositionSamples(),
                "lengthSamples": sliceSettingsObject.lengthSamples(),
                "loopDeltaSamples": sliceSettingsObject.loopDeltaSamples(),
                "loopDelta2Samples": sliceSettingsObject.loopDelta2Samples(),
                "subvoices": subvoiceSettingsData,
                "subvoiceCount": sliceSettingsObject.subvoiceCount()
            })
        return {
            "settings": sliceSettingsData,
            "count": self.clip.audioSource.sliceCount(),
            "contiguous": self.clip.audioSource.slicesContiguous()
        }

    def read(self, load_autosave=True):
        self.__isReading = True
        if not self.clip.isEmpty:
            try:
                file = taglib.File(self.clip.path)
                if load_autosave and "AUTOSAVE" in file.tags:
                    logging.debug(f"Clip metadata reading {self.clip} : autosave")
                    self.__audioMetadata = json.loads(file.tags["AUTOSAVE"][0])
                else:
                    logging.debug(f"Clip metadata reading {self.clip} : NOT autosave")
                    self.__audioMetadata = file.tags
                file.close()
            except Exception as e:
                self.__audioMetadata = None
                logging.error(f"Error reading metadata from sketch {self.clip.path} : {str(e)}")

            # TODO Probably have some fault safety here, in case there's bunk metadata?
            if self.clip.audioSource is not None:
                # The clip's non-playback metadata (essentially unbouncing support data)
                self.set_audioType(str(self.getMetadataProperty("ZYNTHBOX_TRACK_TYPE", None)), write=False, force=True)
                self.set_audioTypeSettings(str(self.getMetadataProperty("ZYNTHBOX_TRACK_AUDIOTYPESETTINGS", None)), write=False, force=True)
                self.set_midiRecording(str(self.getMetadataProperty("ZYNTHBOX_MIDI_RECORDING", None)), write=False, force=True)
                self.set_patternJson(str(self.getMetadataProperty("ZYNTHBOX_PATTERN_JSON", None)), write=False, force=True)
                self.set_routingStyle(str(self.getMetadataProperty("ZYNTHBOX_ROUTING_STYLE", None)), write=False, force=True)
                self.set_samplePickingStyle(str(self.getMetadataProperty("ZYNTHBOX_SAMPLE_PICKING_STYLE", None)), write=False, force=True)
                self.set_samples(str(self.getMetadataProperty("ZYNTHBOX_SAMPLES", None)), write=False, force=True)
                self.set_soundSnapshot(str(self.getMetadataProperty("ZYNTHBOX_SOUND_SNAPSHOT", None)), write=False, force=True)
                # The clip's playback related settings
                self.clip.audioSource.setBpm(float(self.getMetadataProperty("ZYNTHBOX_BPM", Zynthbox.SyncTimer.instance().getBpm())))
                self.clip.audioSource.setSpeedRatio(float(self.getMetadataProperty("ZYNTHBOX_SPEED_RATIO", self.clip.initialSpeedRatio)))
                self.clip.audioSource.setAutoSynchroniseSpeedRatio(str(self.getMetadataProperty("ZYNTHBOX_SYNC_SPEED_TO_BPM", True)).lower() == "true")
                self.set_equaliserSettings(str(self.getMetadataProperty("ZYNTHBOX_EQUALISER_SETTINGS", "")))
                self.set_sliceSettings(str(self.getMetadataProperty("ZYNTHBOX_SLICE_SETTINGS", "")))
                # The slice related settings (for the root slice)
                self.clip.audioSource.rootSlice().setPan(float(self.getMetadataProperty("ZYNTHBOX_PAN", 0)))
                self.clip.audioSource.rootSlice().setRootNote(int(self.getMetadataProperty("ZYNTHBOX_ROOT_NOTE", 60)))
                self.clip.audioSource.rootSlice().setKeyZoneStart(int(self.getMetadataProperty("ZYNTHBOX_KEYZONE_START", 0)))
                self.clip.audioSource.rootSlice().setKeyZoneEnd(int(self.getMetadataProperty("ZYNTHBOX_KEYZONE_END", 127)))
                self.clip.audioSource.rootSlice().setVelocityMinimum(int(self.getMetadataProperty("ZYNTHBOX_VELOCITY_MINIMUM", 1)))
                self.clip.audioSource.rootSlice().setVelocityMaximum(int(self.getMetadataProperty("ZYNTHBOX_VELOCITY_MAXIMUM", 127)))
                self.clip.audioSource.rootSlice().setADSRAttack(float(self.getMetadataProperty("ZYNTHBOX_ADSR_ATTACK", 0)))
                self.clip.audioSource.rootSlice().setADSRDecay(float(self.getMetadataProperty("ZYNTHBOX_ADSR_DECAY", 0)))
                self.clip.audioSource.rootSlice().setADSRSustain(float(self.getMetadataProperty("ZYNTHBOX_ADSR_SUSTAIN", 1)))
                self.clip.audioSource.rootSlice().setADSRRelease(float(self.getMetadataProperty("ZYNTHBOX_ADSR_RELEASE", 0.05)))
                self.clip.audioSource.rootSlice().gainHandler().setGainAbsolute(float(self.getMetadataProperty("ZYNTHBOX_GAIN", self.clip.initialGain)))
                self.clip.audioSource.rootSlice().setGrainInterval(float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_INTERVAL", 10)))
                self.clip.audioSource.rootSlice().setGrainIntervalAdditional(float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_INTERVAL_ADDITIONAL", 10)))
                self.clip.audioSource.rootSlice().setGrainPanMaximum(float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_PAN_MAXIMUM", 1)))
                self.clip.audioSource.rootSlice().setGrainPanMinimum(float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_PAN_MINIMUM", -1)))
                self.clip.audioSource.rootSlice().setGrainPitchMaximum1(float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_PITCH_MAXIMUM1", 1.0)))
                self.clip.audioSource.rootSlice().setGrainPitchMaximum2(float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_PITCH_MAXIMUM2", 1.0)))
                self.clip.audioSource.rootSlice().setGrainPitchMinimum1(float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_PITCH_MINIMUM1", 1.0)))
                self.clip.audioSource.rootSlice().setGrainPitchMinimum2(float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_PITCH_MINIMUM2", 1.0)))
                self.clip.audioSource.rootSlice().setGrainPitchPriority(float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_PITCH_PRIORITY", 0.5)))
                self.clip.audioSource.rootSlice().setGrainPosition(float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_POSITION", 0)))
                self.clip.audioSource.rootSlice().setGrainScan(float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_SCAN", 0)))
                self.clip.audioSource.rootSlice().setGrainSize(float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_SIZE", 100)))
                self.clip.audioSource.rootSlice().setGrainSizeAdditional(float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_SIZE_ADDITIONAL", 50)))
                self.clip.audioSource.rootSlice().setGrainSpray(float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_SPRAY", 1)))
                self.clip.audioSource.rootSlice().setGrainSustain(float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_SUSTAIN", 0.3)))
                self.clip.audioSource.rootSlice().setGrainTilt(float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_TILT", 0.5)))
                self.set_timeStretchStyle(str(self.getMetadataProperty("ZYNTHBOX_TIMESTRETCHSTYLE", "")), -1)
                self.clip.audioSource.rootSlice().setPitch(float(self.getMetadataProperty("ZYNTHBOX_PITCH", self.clip.initialPitch)))
                self.set_playbackStyle(str(self.getMetadataProperty("ZYNTHBOX_PLAYBACK_STYLE", "LoopingPlaybackStyle")), -1)
                self.clip.audioSource.rootSlice().setLoopCrossfadeAmount(float(self.getMetadataProperty("ZYNTHBOX_LOOP_CROSSFADE_AMOUNT", 0)))
                self.set_loopStartCrossfadeDirection(self.getMetadataProperty("ZYNTHBOX_LOOP_START_CROSSFADE_DIRECTION", "CrossfadeOutie"), -1)
                self.set_stopCrossfadeDirection(self.getMetadataProperty("ZYNTHBOX_STOP_CROSSFADE_DIRECTION", "CrossfadeOutie"), -1)
                self.clip.audioSource.rootSlice().setSnapLengthToBeat(str(self.getMetadataProperty("ZYNTHBOX_SNAP_LENGTH_TO_BEAT", True)).lower() == "true")
                self.clip.audioSource.rootSlice().setSubvoiceCount(int(self.getMetadataProperty("ZYNTHBOX_SUBVOICE_COUNT", 0)))
                rootSliceSubvoices = str(self.getMetadataProperty("ZYNTHBOX_SUBVOICE_SETTINGS", ""))
                if len(rootSliceSubvoices) > 0:
                    try:
                        sliceValues = json.loads(rootSliceSubvoices)
                        for index, subvoiceValues in enumerate(sliceValues):
                            self.clip.audioSource.rootSlice().subvoiceSettings()[index].setPan(subvoiceValues["pan"])
                            self.clip.audioSource.rootSlice().subvoiceSettings()[index].setPitch(subvoiceValues["pitch"])
                            self.clip.audioSource.rootSlice().subvoiceSettings()[index].setGain(subvoiceValues["gain"])
                    except Exception as e:
                        logging.error(f"Got us an error unwrapping the voices: {str(e)}\nFrom the stored string:{rootSliceSubvoices}")
                else:
                    logging.error("No subvoices, apparently...")
                # Some fallbackery that we can likely remove at some point (or also perhaps get rid of entirely when we switch to using the industry version of slice and loop definitions...)
                startPositionSamples = float(self.getMetadataProperty("ZYNTHBOX_STARTPOSITION_SAMPLES", -1))
                if startPositionSamples == -1:
                    self.clip.audioSource.rootSlice().setStartPositionSeconds(float(self.getMetadataProperty("ZYNTHBOX_STARTPOSITION", self.clip.initialStartPosition)))
                else:
                    self.clip.audioSource.rootSlice().setStartPositionSamples(startPositionSamples)
                lengthSamples = float(self.getMetadataProperty("ZYNTHBOX_LENGTH_SAMPLES", -1))
                if lengthSamples == -1:
                    self.clip.audioSource.rootSlice().setLengthBeats(float(self.getMetadataProperty("ZYNTHBOX_LENGTH", self.clip.initialLength)))
                else:
                    self.clip.audioSource.rootSlice().setLengthSamples(lengthSamples)
                loopDeltaSamples = float(self.getMetadataProperty("ZYNTHBOX_LOOPDELTA_SAMPLES", -1))
                if loopDeltaSamples == -1:
                    self.clip.audioSource.rootSlice().setLoopDeltaSeconds(float(self.getMetadataProperty("ZYNTHBOX_LOOPDELTA", 0.0)))
                else:
                    self.clip.audioSource.rootSlice().setLoopDeltaSamples(loopDeltaSamples)
                loopDelta2Samples = float(self.getMetadataProperty("ZYNTHBOX_LOOPDELTA2_SAMPLES", -1))
                if loopDelta2Samples == -1:
                    self.clip.audioSource.rootSlice().setLoopDelta2Seconds(float(self.getMetadataProperty("ZYNTHBOX_LOOPDELTA2", 0.0)))
                else:
                    self.clip.audioSource.rootSlice().setLoopDelta2Samples(loopDelta2Samples)
        self.__isReading = False

    @Slot()
    def writeMetadataWithoutSoundData(self):
        self.write(writeSoundMetadata=False)

    @Slot()
    def writeMetadataWithSoundData(self):
        self.write(writeSoundMetadata=True)

    def write(self, writeSoundMetadata=False, isAutosave=True):
        if self.__isReading == False and self.clip.__song__.isLoading == False and self.clip.__song__.isSaving == False:
            if not self.clip.isEmpty:
                tags = {}
                if writeSoundMetadata:
                    # When writing sound metadata, first set updated values to the respective properties and then write
                    self.set_audioType(self.clip.channel.trackType, write=False, force=True)
                    self.set_audioTypeSettings(self.clip.channel.getAudioTypeSettings(), write=False, force=True)
                    # TODO : Metadata Check if midi recording is correct or not
                    if self.clip.zynqtgui.sketchpad.lastRecordingMidi == "":
                        # If there is no midi recording (that is, if this was not a live-recorded bit of audio), then save the clip's pattern data and ensure the midi recording meta is empty
                        self.set_midiRecording("", write=False, force=True)
                        sequenceObject = Zynthbox.PlayGridManager.instance().getSequenceModel(self.clip.zynqtgui.sketchpad.song.scenesModel.selectedSequenceName)
                        patternObject = sequenceObject.getByClipId(self.clip.channel.id, self.clip.id)
                        self.set_patternJson(patternObject.toJson(), write=False, force=True)
                    else:
                        # If there is a midi recording, store that, and ensure the pattern json is empty
                        self.set_midiRecording(self.clip.zynqtgui.sketchpad.lastRecordingMidi, write=False, force=True)
                        self.set_patternJson("", write=False, force=True)
                    self.set_routingStyle(self.clip.channel.trackRoutingStyle, write=False, force=True)
                    self.set_samplePickingStyle(self.clip.channel.samplePickingStyle, write=False, force=True)
                    self.set_samples(self.clip.channel.getChannelSampleSnapshot(), write=False, force=True)
                    self.set_soundSnapshot(self.clip.channel.getChannelSoundSnapshotJson(), write=False, force=True)

                    tags["ZYNTHBOX_TRACK_TYPE"] = [str(self.__audioType)]
                    tags["ZYNTHBOX_TRACK_AUDIOTYPESETTINGS"] = [str(self.__audioTypeSettings)]
                    tags["ZYNTHBOX_MIDI_RECORDING"] = [str(self.__midiRecording)]
                    tags["ZYNTHBOX_PATTERN_JSON"] = [str(self.__patternJson)]
                    tags["ZYNTHBOX_ROUTING_STYLE"] = [str(self.__routingStyle)]
                    tags["ZYNTHBOX_SAMPLE_PICKING_STYLE"] = [str(self.__samplePickingStyle)]
                    tags["ZYNTHBOX_SAMPLES"] = [str(self.__samples)]
                    tags["ZYNTHBOX_SOUND_SNAPSHOT"] = [str(self.__soundSnapshot)]
                if self.clip.audioSource:
                    tags["ZYNTHBOX_BPM"] = [str(self.clip.audioSource.bpm())]
                    tags["ZYNTHBOX_SPEED_RATIO"] = [str(self.clip.audioSource.speedRatio())]
                    tags["ZYNTHBOX_SYNC_SPEED_TO_BPM"] = [str(self.clip.audioSource.autoSynchroniseSpeedRatio())]
                    tags["ZYNTHBOX_EQUALISER_SETTINGS"] = [str(json.dumps(serializeEqualiserAndCompressorSettings(self.clip.audioSource)))]
                    tags["ZYNTHBOX_SLICE_SETTINGS"] = [str(json.dumps(self.serializeSliceSettings()))]
                    # Root slice settings
                    tags["ZYNTHBOX_ROOT_NOTE"] = [str(self.clip.audioSource.rootSlice().rootNote())]
                    tags["ZYNTHBOX_KEYZONE_START"] = [str(self.clip.audioSource.rootSlice().keyZoneStart())]
                    tags["ZYNTHBOX_KEYZONE_END"] = [str(self.clip.audioSource.rootSlice().keyZoneEnd())]
                    tags["ZYNTHBOX_VELOCITY_MINIMUM"] = [str(self.clip.audioSource.rootSlice().velocityMinimum())]
                    tags["ZYNTHBOX_VELOCITY_MAXIMUM"] = [str(self.clip.audioSource.rootSlice().velocityMaximum())]
                    tags["ZYNTHBOX_PAN"] = [str(self.clip.audioSource.rootSlice().pan())]
                    tags["ZYNTHBOX_GAIN"] = [str(self.clip.audioSource.rootSlice().gainHandler().gainAbsolute())]
                    tags["ZYNTHBOX_ADSR_ATTACK"] = [str(self.clip.audioSource.rootSlice().adsrAttack())]
                    tags["ZYNTHBOX_ADSR_DECAY"] = [str(self.clip.audioSource.rootSlice().adsrDecay())]
                    tags["ZYNTHBOX_ADSR_RELEASE"] = [str(self.clip.audioSource.rootSlice().adsrRelease())]
                    tags["ZYNTHBOX_ADSR_SUSTAIN"] = [str(self.clip.audioSource.rootSlice().adsrSustain())]
                    tags["ZYNTHBOX_GRAINERATOR_INTERVAL"] = [str(self.clip.audioSource.rootSlice().grainInterval())]
                    tags["ZYNTHBOX_GRAINERATOR_INTERVAL_ADDITIONAL"] = [str(self.clip.audioSource.rootSlice().grainIntervalAdditional())]
                    tags["ZYNTHBOX_GRAINERATOR_PAN_MAXIMUM"] = [str(self.clip.audioSource.rootSlice().grainPanMaximum())]
                    tags["ZYNTHBOX_GRAINERATOR_PAN_MINIMUM"] = [str(self.clip.audioSource.rootSlice().grainPanMinimum())]
                    tags["ZYNTHBOX_GRAINERATOR_PITCH_MAXIMUM1"] = [str(self.clip.audioSource.rootSlice().grainPitchMaximum1())]
                    tags["ZYNTHBOX_GRAINERATOR_PITCH_MAXIMUM2"] = [str(self.clip.audioSource.rootSlice().grainPitchMaximum2())]
                    tags["ZYNTHBOX_GRAINERATOR_PITCH_MINIMUM1"] = [str(self.clip.audioSource.rootSlice().grainPitchMinimum1())]
                    tags["ZYNTHBOX_GRAINERATOR_PITCH_MINIMUM2"] = [str(self.clip.audioSource.rootSlice().grainPitchMinimum2())]
                    tags["ZYNTHBOX_GRAINERATOR_PITCH_PRIORITY"] = [str(self.clip.audioSource.rootSlice().grainPitchPriority())]
                    tags["ZYNTHBOX_GRAINERATOR_POSITION"] = [str(self.clip.audioSource.rootSlice().grainPosition())]
                    tags["ZYNTHBOX_GRAINERATOR_SCAN"] = [str(self.clip.audioSource.rootSlice().grainScan())]
                    tags["ZYNTHBOX_GRAINERATOR_SIZE"] = [str(self.clip.audioSource.rootSlice().grainSize())]
                    tags["ZYNTHBOX_GRAINERATOR_SIZE_ADDITIONAL"] = [str(self.clip.audioSource.rootSlice().grainSizeAdditional())]
                    tags["ZYNTHBOX_GRAINERATOR_SPRAY"] = [str(self.clip.audioSource.rootSlice().grainSpray())]
                    tags["ZYNTHBOX_GRAINERATOR_SUSTAIN"] = [str(self.clip.audioSource.rootSlice().grainSustain())]
                    tags["ZYNTHBOX_GRAINERATOR_TILT"] = [str(self.clip.audioSource.rootSlice().grainTilt())]
                    tags["ZYNTHBOX_STARTPOSITION_SAMPLES"] = [str(self.clip.audioSource.rootSlice().startPositionSamples())]
                    tags["ZYNTHBOX_SNAP_LENGTH_TO_BEAT"] = [str(self.clip.audioSource.rootSlice().snapLengthToBeat())]
                    tags["ZYNTHBOX_LENGTH_SAMPLES"] = [str(self.clip.audioSource.rootSlice().lengthSamples())]
                    tags["ZYNTHBOX_LOOPDELTA_SAMPLES"] = [str(self.clip.audioSource.rootSlice().loopDeltaSamples())]
                    tags["ZYNTHBOX_LOOPDELTA2_SAMPLES"] = [str(self.clip.audioSource.rootSlice().loopDelta2Samples())]
                    tags["ZYNTHBOX_LOOP_CROSSFADE_AMOUNT"] = [str(self.clip.audioSource.rootSlice().loopCrossfadeAmount())]
                    tags["ZYNTHBOX_LOOP_START_CROSSFADE_DIRECTION"] = [str(self.clip.audioSource.rootSlice().loopStartCrossfadeDirection()).split(".")[-1]]
                    tags["ZYNTHBOX_STOP_CROSSFADE_DIRECTION"] = [str(self.clip.audioSource.rootSlice().stopCrossfadeDirection()).split(".")[-1]]
                    tags["ZYNTHBOX_PITCH"] = [str(self.clip.audioSource.rootSlice().pitch())]
                    tags["ZYNTHBOX_PLAYBACK_STYLE"] = [str(self.clip.audioSource.rootSlice().playbackStyle()).split(".")[-1]]
                    tags["ZYNTHBOX_TIMESTRETCHSTYLE"] = [str(self.clip.audioSource.rootSlice().timeStretchStyle()).split(".")[-1]]
                    tags["ZYNTHBOX_SUBVOICE_COUNT"] = [str(self.clip.audioSource.rootSlice().subvoiceCount())]
                    rootSliceSubvoices = []
                    for subvoiceSettingsObject in self.clip.audioSource.rootSlice().subvoiceSettings():
                        rootSliceSubvoices.append({
                            "pan": subvoiceSettingsObject.pan(),
                            "pitch": subvoiceSettingsObject.pitch(),
                            "gain": subvoiceSettingsObject.gain()
                        })
                    tags["ZYNTHBOX_SUBVOICE_SETTINGS"] = [str(json.dumps(rootSliceSubvoices))]

                try:
                    file = taglib.File(self.clip.path)
                    if isAutosave and not self.clip.__song__.isTemp:
                        logging.debug(f"Clip metadata writing {self.clip} : autosave")
                        file.tags["AUTOSAVE"] = [str(json.dumps(tags))]
                    else:
                        logging.debug(f"Clip metadata writing {self.clip} : NOT autosave")
                        for key, value in tags.items():
                            file.tags[key] = value
                    file.save()
                except Exception as e:
                    logging.exception(f"Error writing metadata : {str(e)}")
                    logging.info("Trying to create a new file without metadata")

                    try:
                        with tempfile.TemporaryDirectory() as tmp:
                            logging.info("Creating new temp file without metadata")
                            logging.debug(f"ffmpeg -i {self.clip.path} -codec copy {Path(tmp) / 'output.wav'}")
                            check_output(f"ffmpeg -i {self.clip.path} -codec copy {Path(tmp) / 'output.wav'}", shell=True)

                            logging.info("Replacing old file")
                            logging.debug(f"mv {Path(tmp) / 'output.wav'} {self.clip.path}")
                            check_output(f"mv {Path(tmp) / 'output.wav'} {self.clip.path}", shell=True)

                            file = taglib.File(self.clip.path)
                            if isAutosave:
                                logging.debug("Clip metadata writing : autosave")
                                file.tags["AUTOSAVE"] = [str(json.dumps(tags))]
                            else:
                                logging.debug("Clip metadata writing : NOT autosave")
                                for key, value in tags.items():
                                    file.tags[key] = value
                            file.save()
                    except Exception as e:
                        logging.error(f"Error creating new file and writing metadata : {str(e)}")
            self.__isWriting = False

    def scheduleWrite(self):
        if self.__isReading == False and self.__isWriting == False and self.clip.__song__.isLoading == False and self.clip.__song__.isSaving == False:
            self.__isWriting = True
            # Do not explicitly make a call to write as song save will be saving metadata as required
            self.clip.__song__.schedule_save()

    def clear(self):
        # Channel settings for the clip (stored in metadata when bouncing, but not settable from the UI)
        self.set_audioType(None, write=False, force=True)
        self.set_audioTypeSettings(None, write=False, force=True)
        self.set_midiRecording(None, write=False, force=True)
        self.set_patternJson(None, write=False, force=True)
        self.set_routingStyle(None, write=False, force=True)
        self.set_samplePickingStyle(None, write=False, force=True)
        self.set_samples(None, write=False, force=True)
        self.set_soundSnapshot(None, write=False, force=True)


class sketchpad_clip(QObject):
    def __init__(self, row_index: int, col_index: int, id: int, song: QObject, parent=None, is_channel_sample=False):
        super(sketchpad_clip, self).__init__(parent)
        self.zynqtgui = zynthian_gui_config.zynqtgui

        self.is_channel_sample = is_channel_sample
        self.__row_index__ = row_index
        self.__col_index__ = col_index
        self.__id__ = id
        self.__path__ = None
        self.__filename__ = ""
        self.__song__ = song
        self.__initial_length__ = 4
        self.__initial_start_position__ = 0.0
        self.__initial_pitch__ = 0
        self.__initial_speed_ratio = 1
        self.__speed_ratio__ = self.__initial_speed_ratio
        self.__initial_gain__ = 0.50 # This represents a gainAbsolute value which is roughly equivalent to 0dB
        self.__progress__ = 0.0
        self.audioSource = None
        self.recording_basepath = song.sketchpad_folder
        self.wav_path = Path(self.__song__.sketchpad_folder) / 'wav'
        self.__slices__ = 16
        self.__enabled__ = False
        self.channel = None
        self.__lane__ = id
        self.__metadata = sketchpad_clip_metadata(self)

        # Just in case, fix up the lane so it's something sensible (we have five lanes, so...)
        if self.__lane__ < 0 or self.__lane__ > 4:
            self.__lane__ = 0

        self.__autoStopTimer__ = QTimer()
        self.__autoStopTimer__.setSingleShot(True)
        self.__autoStopTimer__.timeout.connect(self.stop_audio)

        try:
            # Check if a dir named <somerandomname>.<channel_id> exists.
            # If exists, use that name as the bank dir name otherwise use default name `sample-bank`
            bank_name = [x.name for x in self.__base_samples_dir__.glob(f"*.{self.id + 1}")][0].split(".")[0]
        except:
            bank_name = "sample-bank"
        self.bank_path = Path(self.__song__.sketchpad_folder) / 'wav' / 'sampleset' / f'{bank_name}.{self.row + 1}'

        try:
            self.channel = self.__song__.channelsModel.getChannel(self.__row_index__)
        except:
            pass

        self.__sync_in_current_scene_timer__ = QTimer()
        self.__sync_in_current_scene_timer__.setSingleShot(True)
        self.__sync_in_current_scene_timer__.setInterval(50)
        self.__sync_in_current_scene_timer__.timeout.connect(self.in_current_scene_changed.emit)

        self.__was_in_current_scene = self.get_in_current_scene()
        self.__song__.scenesModel.selected_scene_index_changed.connect(self.__sync_in_current_scene_timer__.start)

        self.path_changed.connect(self.zynqtgui.zynautoconnect_audio)
        self.__metadata.soundSnapshotChanged.connect(self.sketchContainsSoundChanged.emit)
        self.__metadata.samplesChanged.connect(self.sketchContainsSamplesChanged.emit)

    # A helper method to generate unique name when copying a wave file into a folder
    # Arg file : Full Path of file to be copied
    # Arg copy_dir : Full Path of destination dir where the file will be copied
    # Returns : An unique filename as string in the format f"{file_basename}-{counter}.{category}.wav" (where category is either "clip" or "sketch")
    @staticmethod
    def generate_unique_filename(file, copy_dir):
        file_path = Path(file)
        copy_dir_path = Path(copy_dir)
        counter = 1

        # Find the base filename excluding our suffix (wav)
        file_basename = file_path.name.split(".wav")[0]
        # Remove the `counter` part from the string if exists
        file_basename = re.sub('-\d*$', '', file_basename)

        if not (copy_dir_path / f"{file_basename}.wav").exists():
            return f"{file_basename}.wav"
        else:
            while Path(copy_dir_path / f"{file_basename}-{counter}.wav").exists():
                counter += 1

            return f"{file_basename}-{counter}.wav"

    def className(self):
        return "sketchpad_clip"

    ### Property initialStartPosition
    def get_initial_start_position(self):
        return self.__initial_start_position__
    initialStartPosition = Property(float, get_initial_start_position, constant=True)
    ### END Property initialStartPosition

    ### Property clipChannel
    def get_channel(self):
        return self.channel
    clipChannel = Property(QObject, get_channel, constant=True)
    ### END Property clipChannel

    ### Property initialLength
    def get_initial_length(self):
        return self.__initial_length__
    initialLength = Property(int, get_initial_length, constant=True)
    ### END Property initialLength

    ### Property initialPitch
    def get_initial_pitch(self):
        return self.__initial_pitch__
    initialPitch = Property(int, get_initial_pitch, constant=True)
    ### END Property initialPitch

    ### Property initialTime
    def get_initialSpeedRatio(self):
        return self.__initial_speed_ratio
    initialSpeedRatio = Property(float, get_initialSpeedRatio, constant=True)
    ### END Property initialTime

    ### Property initialGain
    def get_initial_gain(self):
        return self.__initial_gain__
    initialGain = Property(float, get_initial_gain, constant=True)
    ### END Property initialGain

    def serialize(self):
        return {
            "path": self.__path__,
            "enabled": self.__enabled__
        }

    def deserialize(self, obj, load_autosave=True):
        logging.debug(f"clip_deserialize : {load_autosave}")
        try:
            if "path" in obj:
                if obj["path"] is None:
                    self.__path__ = None
                else:
                    if self.is_channel_sample:
                        self.set_path(str(self.bank_path / obj["path"]), False, load_autosave)
                    else:
                        self.set_path(str(self.wav_path / obj["path"]), False, load_autosave)
            if "enabled" in obj:
                self.__enabled__ = obj["enabled"]
                self.set_enabled(self.__enabled__, True)
        except Exception as e:
            logging.error(f"Error during clip deserialization: {e}")
            traceback.print_exception(None, e, e.__traceback__)

    @Signal
    def row_index_changed(self):
        pass

    @Signal
    def col_index_changed(self):
        pass

    @Signal
    def path_changed(self):
        pass

    def playable(self):
        return True
    playable = Property(bool, playable, constant=True)

    def recordable(self):
        return True
    recordable = Property(bool, recordable, constant=True)

    def clearable(self):
        return True
    clearable = Property(bool, clearable, constant=True)

    def deletable(self):
        return False
    deletable = Property(bool, deletable, constant=True)

    def nameEditable(self):
        return False
    nameEditable = Property(bool, nameEditable, constant=True)

    # BEGIN Property isPlaying
    @Signal
    def is_playing_changed(self):
        pass

    def get_isPlaying(self):
        if self.audioSource is None:
            return False
        return self.audioSource.isPlaying

    isPlaying = Property(bool, get_isPlaying, notify=is_playing_changed)
    # END Property isPlaying

    @Signal
    def progressChanged(self):
        pass

    def get_progress(self):
        if self.audioSource is None:
            return 0.0
        return self.__progress__

    progress = Property(float, get_progress, notify=progressChanged)

    def row(self):
        return self.__row_index__

    def set_row_index(self, new_index):
        self.__row_index__ = new_index

        try:
            self.channel = self.__song__.channelsModel.getChannel(self.__row_index__)
            self.bank_path = Path(self.__song__.sketchpad_folder) / 'wav' / 'sampleset' / f'sample-bank.{new_index + 1}'
        except:
            pass
        self.row_index_changed.emit()

    row = Property(int, row, set_row_index, notify=row_index_changed)


    def col(self):
        return self.__col_index__

    def set_col_index(self, index):
        self.__col_index__ = index
        self.col_index_changed.emit()

    col = Property(int, col, set_col_index, notify=col_index_changed)


    def id(self):
        return self.__id__
    def set_id(self, index):
        if self.__id__ != index:
            self.__id__ = index
            self.id_changed.emit()
    id_changed = Signal()
    id = Property(int, id, set_id, notify=id_changed)

    def lane(self):
        return self.__lane__

    def set_lane(self, lane: int):
        if self.__lane__ != lane:
            self.__lane__ = lane
            if self.audioSource is not None:
                self.audioSource.setLaneAffinity(lane)
            self.lane_changed.emit()

    @Signal
    def lane_changed(self):
        pass

    lane = Property(int, lane, set_lane, notify=lane_changed)

    def name(self):
        return f"{self.get_channel_name()}-{self.get_clip_name()}"
    name = Property(str, name, constant=True)


    def get_clip_name(self):
        return chr(self.__col_index__+65)
    clipName = Property(str, get_clip_name, constant=True)

    @Signal
    def duration_changed(self):
        pass

    def duration(self):
        if self.audioSource is None:
            return 0.0
        return self.audioSource.getDuration()

    duration = Property(float, duration, notify=duration_changed)

    def filename(self):
        return self.__filename__

    def path(self):
        if self.__path__ is None:
            return None
        else:
            if self.is_channel_sample:
                return str(self.bank_path / self.__path__)
            else:
                return str(self.wav_path / self.__path__)

    # Arg path : Set path of the wav to clip
    # Arg should_copy : Controls where the selected clip should be copied under a unique name when setting.
    #                   should_copy should be set to False when restoring to avoid copying the same clip under
    #                   a different name. Otherwise when path is set from UI, it makes sure to always create a new file
    #                   when first selecting a wav for a clip.
    @Slot(str,bool)
    def set_path(self, path, should_copy=True, load_autosave=True):
        logging.debug(f"{path}, {should_copy}, {load_autosave}")
        if path is not None:
            selected_path = Path(path)
            new_filename = ""

            if self.is_channel_sample:
                if should_copy:
                    new_filename = self.generate_unique_filename(selected_path, self.bank_path)
                    logging.info(f"Copying sample({path}) into bank folder ({self.bank_path / new_filename})")
                    self.bank_path.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(selected_path, self.bank_path / new_filename)
            else:
                if should_copy:
                    new_filename = self.generate_unique_filename(selected_path, self.wav_path)
                    logging.info(f"Copying clip({path}) into sketchpad folder ({self.wav_path / new_filename})")
                    shutil.copy2(selected_path, self.wav_path / new_filename)

            if new_filename == "" :
                self.__path__ = str(selected_path.name)
            else:
                self.__path__ = str(new_filename)
            self.__filename__ = self.__path__.split("/")[-1]
            self.stop()
        else:
            self.__path__ = None
            self.metadata.clear()

        if self.audioSource is not None:
            self.__metadata.unhook()
            try: self.audioSource.disconnect(self)
            except: pass

        self.zynqtgui.currentTaskMessage = f"Loading Sketchpad : Loading Sample<br/>{self.__filename__}"
        if path is not None:
            self.audioSource = Zynthbox.ClipAudioSource(path, False, self)
            self.audioSource.rootSlice().lengthChanged.connect(self.sec_per_beat_changed.emit)
            self.audioSource.isPlayingChanged.connect(self.is_playing_changed.emit)
            self.audioSource.progressChanged.connect(self.progress_changed_cb, Qt.QueuedConnection)
            self.audioSource.setLaneAffinity(self.__lane__)
            if self.clipChannel is not None:
                self.audioSource.setSketchpadTrack(self.clipChannel.id)
        else:
            self.audioSource = None

        # read() will read all the available metadata and populate default values if not available
        self.__metadata.read(load_autosave)
        self.__metadata.hook()
        self.__progress__ = 0.0

        self.cppObjIdChanged.emit()
        self.path_changed.emit()
        self.duration_changed.emit()
        self.is_playing_changed.emit()
        if self.is_channel_sample:
            self.__song__.channelsModel.getChannel(self.row).samples_changed.emit()
        self.__song__.schedule_save()

    path = Property(str, path, set_path, notify=path_changed)
    filename = Property(str, filename, notify=path_changed)

    # Copies the file to the given location
    # To perform a true save-as, to copyTo(someFilename), and then setPath(someFilename)
    @Slot(str, result=bool)
    def copyTo(self, copyToFilename):
        if self.audioSource is not None:
            if os.path.exists(self.audioSource.getFilePath()):
                if shutil.copy2(self.audioSource.getFilePath(), copyToFilename):
                    return True
                else:
                    logging.error(f"Failed to copy {self.audioSource.getFilePath()} to {copyToFilename}")
            else:
                logging.error(f"Attempted to copy non-existent file {self.audioSource.getFilePath()} to {copyToFilename}")
        else:
            logging.error(f"Attempted to copy a clip with no audio source to {copyToFilename}")
        return False

    def progress_changed_cb(self):
        self.__progress__ = self.audioSource.progress()
        self.progressChanged.emit()

    @Slot(None)
    def clear(self, loop=True):
        self.stop()
        # TODO : Metadata Clear metadata
        if self.audioSource is not None:
            self.audioSource.deleteLater()
            self.audioSource = None
            self.cppObjIdChanged.emit()

        self.set_path(None, False)
        self.__filename__ = ""
        if self.is_channel_sample:
            self.__song__.channelsModel.getChannel(self.row).samples_changed.emit()

        self.__song__.schedule_save()

    @Slot(None)
    def play(self):
        # if not self.isPlaying:
            # We will now allow playing multiple clips on sample-loop channel and hence do not stop other clips on that track when playing
            # if self.channel is not None:
            #     clipsModel = self.channel.clipsModel
            #
            #     for clip_index in range(0, clipsModel.count):
            #         clip: sketchpad_clip = clipsModel.getClip(clip_index)
            #         logging.debug(f"Channel({self.channel}), Clip({clip}: isPlaying({clip.isPlaying}))")
            #
            #         if clip.isPlaying:
            #             clip.stop()

        if self.channel is None:
            # if channel is none, it means this clip is a sample rather than a clip and needs to be just... played
            self.play_audio(True)
        else:
            # logging.info(f"Setting Clip To Play from the beginning at the top of the next bar {self} track {self.channel.id} clip {self.id}")
            # Until we work out what to actually do with the whole "more than one songs" thing, this will do
            songIndex = 0
            Zynthbox.PlayfieldManager.instance().setClipPlaystate(songIndex, self.channel.id, self.id, Zynthbox.PlayfieldManager.PlaybackState.PlayingState, Zynthbox.PlayfieldManager.PlayfieldStatePosition.NextBarPosition, 0)

    @Slot(None)
    def stop(self):
        # logging.info(f"Setting Clip to Stop at the top of the next bar {self}")
        if self.channel is None:
            # if channel is none, it means this clip is a sample rather than a clip and needs to be just... stopped
            self.stop_audio()
        else:
            # Until we work out what to actually do with the whole "more than one songs" thing, this will do
            songIndex = 0
            if Zynthbox.SyncTimer.instance().timerRunning:
                # logging.info(f"Setting Clip To Stop from the beginning at the top of the next bar {self} track {self.channel.id} clip {self.id}")
                Zynthbox.PlayfieldManager.instance().setClipPlaystate(songIndex, self.channel.id, self.id, Zynthbox.PlayfieldManager.PlaybackState.StoppedState, Zynthbox.PlayfieldManager.PlayfieldStatePosition.NextBarPosition, 0)
            else:
                # logging.info(f"Setting Clip To Stop immediately {self} track {self.channel.id} clip {self.id}")
                Zynthbox.PlayfieldManager.instance().setClipPlaystate(songIndex, self.channel.id, self.id, Zynthbox.PlayfieldManager.PlaybackState.StoppedState, Zynthbox.PlayfieldManager.PlayfieldStatePosition.CurrentPosition, 0)

    def destroy(self):
        if self.audioSource is not None:
            self.audioSource.deleteLater()

    @Slot(bool)
    def queueRecording(self, do_countin=True):
        return self.__song__.get_metronome_manager().queue_clip_record(self, do_countin)

    @Slot(None)
    def stopRecording(self):
        self.__song__.get_metronome_manager().stopRecording()

    ### BEGIN Property sketchContainsSound
    def get_sketchContainsSound(self):
        if self.metadata.soundSnapshot is not None:
            metadata = self.zynqtgui.layer.sound_metadata_from_json(self.metadata.soundSnapshot)
            # If there are 1 or more layers in snapshot, return True
            return len(metadata) > 0
        return False
    sketchContainsSoundChanged = Signal()
    sketchContainsSound = Property(bool, get_sketchContainsSound, notify=sketchContainsSoundChanged)
    ### END Property sketchContainsSound

    ### BEGIN Property sketchContainsSamples
    def get_sketchContainsSamples(self):
        containsSamples = False
        try:
            if self.metadata.samples is not None:
                samples = json.loads(self.metadata.samples)
                for id in range(5):
                    sample = samples[f"{id}"]
                    # Return true only if there is atleast 1 sample available
                    if "filename" in sample and "sampledata" in sample and not sample["filename"] == "" and not sample["sampledata"] == "":
                        containsSamples = True
                        break
        except:
            containsSamples = False
        return containsSamples
    sketchContainsSamplesChanged = Signal()
    sketchContainsSamples = Property(bool, get_sketchContainsSamples, notify=sketchContainsSamplesChanged)
    ### END Property sketchContainsSamples

    @Signal
    def sec_per_beat_changed(self):
        pass

    def get_secPerBeat(self):
        return 60.0/Zynthbox.SyncTimer.instance().getBpm()

    secPerBeat = Property(float, get_secPerBeat, notify=sec_per_beat_changed)

    def recordingDir(self):
        if self.wav_path.exists():
            return str(self.wav_path)
        else:
            return self.__song__.sketchpad_folder

    # Only use this to do things like previewing the audio. Use play and stop above to control the playback properly
    @Slot(bool)
    def play_audio(self, loop=True):
        if self.audioSource is not None:
            self.audioSource.play(loop)
            self.__autoStopTimer__.setInterval(self.duration * 1000)
            self.__autoStopTimer__.start()

    # Only use this to do things like previewing the audio. Use play and stop above to control the playback properly
    @Slot(None)
    def stop_audio(self):
        if self.audioSource is not None:
            self.__autoStopTimer__.stop()
            self.audioSource.stop()

    @Slot(QObject)
    def copyFrom(self, clip):
        self.clear()
        self.set_path(clip.path, True, True)
        self.enabled = clip.enabled

    @Slot()
    def deleteClip(self):
        def cb(params=None):
            if (self.wav_path / self.__path__).exists():
                (self.wav_path / self.__path__).unlink()
                self.clear()

        self.__song__.get_metronome_manager().zynqtgui.show_confirm("Do you really want to delete this clip? This action is irreversible.", cb)

    ### Property channelName
    def get_channel_name(self):
        channel = self.__song__.channelsModel.getChannel(self.__row_index__)
        return channel.name
    channelName = Property(str, get_channel_name, constant=True)
    ### END Property channelName

    ### Property inCurrentScene
    def get_in_current_scene(self):
        return self.__song__.scenesModel.isClipInCurrentScene(self)
    in_current_scene_changed = Signal()
    inCurrentScene = Property(bool, get_in_current_scene, notify=in_current_scene_changed)
    ### END Property inCurrentScene

    ### Property cppObjId
    def get_cpp_obj_id(self):
        if self.audioSource is not None:
            return self.audioSource.id()
        else:
            return -1

    cppObjIdChanged = Signal()

    cppObjId = Property(int, get_cpp_obj_id, notify=cppObjIdChanged)
    ### END Property cppObjId

    ### Property slices
    def get_slices(self):
        return self.__slices__

    def set_slices(self, val):
        if self.__slices__ != val:
            self.__slices__ = val
            self.slices_changed.emit()
            if self.audioSource is not None:
                self.audioSource.setSlices(val)

    slices_changed = Signal()

    slices = Property(int, get_slices, set_slices, notify=slices_changed)
    ### END Property slices

    ### Property isChannelSample
    def get_is_channel_sample(self):
        return self.is_channel_sample

    isChannelSample = Property(bool, get_is_channel_sample, constant=True)
    ### END Property isChannelSample

    ### BEGIN Property enabled
    def get_enabled(self):
        return self.__enabled__
    def set_enabled(self, enabled, force_set=False):
        if self.__enabled__ != enabled or force_set:
            self.__enabled__ = enabled

            if not self.isChannelSample:
                if self.__enabled__:
                    self.__song__.scenesModel.addClipToCurrentScene(self)
                else:
                    self.__song__.scenesModel.removeClipFromCurrentScene(self)

            self.enabled_changed.emit(self.col, self.id)
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_CLIP_ACTIVE_STATE", -1, Zynthbox.ZynthboxBasics.Track(self.col), Zynthbox.ZynthboxBasics.Slot(self.__id__), 1 if self.__enabled__ else 0)

    enabled_changed = Signal(int, int, arguments=["trackIndex", "clipIndex"])

    enabled = Property(bool, get_enabled, set_enabled, notify=enabled_changed)
    ### END Property enabled

    ### BEGIN property isEmpty
    """
    isEmpty property is for detecting if a clip has some file loaded or not
    It depends on the path property and will get updated with changes to path
    """
    def get_isEmpty(self):
        return self.path is None or len(self.path) == 0

    isEmpty = Property(bool, get_isEmpty, notify=path_changed)
    ### END property isEmpty

    ### BEGIN Property metadata
    def get_metadata(self):
        return self.__metadata

    metadata = Property(QObject, get_metadata, constant=True)
    ### END Property metadata

    className = Property(str, className, constant=True)
    recordingDir = Property(str, recordingDir, constant=True)
