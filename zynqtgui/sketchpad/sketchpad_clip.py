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
import json
import os
import logging
import Zynthbox

from pathlib import Path
from subprocess import check_output
from PySide2.QtCore import Property, QObject, QTimer, Qt, Signal, Slot
from zynqtgui import zynthian_gui_config


class sketchpad_clip_metadata(QObject):
    def __init__(self, clip):
        super(sketchpad_clip_metadata, self).__init__(clip)
        self.clip = clip
        self.__audioMetadata = None
        self.__soundSnapshot = self.clip.channel.getChannelSoundSnapshotJson()
        self.__adsrAttack = 0
        self.__adsrDecay = 0
        self.__adsrRelease = 0.05
        self.__adsrSustain = 1
        self.__audioType = self.clip.channel.trackType
        self.__audioTypeSettings = self.clip.getAudioTypeSettings()
        self.__bpm = Zynthbox.SyncTimer.instance().bpm
        self.__gain = self.clip.initialGain
        self.__graineratorEnabled = False
        self.__graineratorInterval = 10
        self.__graineratorIntervalAdditional = 10
        self.__graineratorPanMaximum = 1
        self.__graineratorPanMinimum = -1
        self.__graineratorPitchMaximum1 = 1.0
        self.__graineratorPitchMaximum2 = 1.0
        self.__graineratorPitchMinimum1 = 1.0
        self.__graineratorPitchMinimum2 = 1.0
        self.__graineratorPitchPriority = 0.5
        self.__graineratorPosition = 0
        self.__graineratorScan = 0
        self.__graineratorSize = 100
        self.__graineratorSizeAdditional = 50
        self.__graineratorSpray = 1
        self.__graineratorSustain = 0.3
        self.__graineratorTilt = 0.5
        self.__length = self.clip.initialLength
        self.__loopdelta = 0.0
        self.__loopdelta2 = 0.0
        self.__midiRecording = ""
        self.__patternJson = ""
        self.__pitch = self.clip.initialPitch
        self.__playbackStyle = self.clip.audioSource.playbackStyle() if self.clip.audioSource is not None else ''
        self.__routingStyle = self.clip.channel.trackRoutingStyle
        self.__samplePickingStyle = self.clip.channel.samplePickingStyle
        self.__samples = self.clip.channel.getChannelSampleSnapshot()
        self.__snapLengthToBeat = True
        self.__speedRatio = self.clip.initialSpeedRatio
        self.__startPosition = self.clip.initialStartPosition
        self.__syncSpeedToBpm = True

    def getMetadataProperty(self, propertyName, defaultValue):
        try:
            if self.__audioMetadata is not None:
                value = self.__audioMetadata[propertyName][0]
                return value
        except:
            return defaultValue

    def readMetadata(self):
        # TODO : Make sure default values of dynamic props like audioType, audioTypeSettings are updated when reading from metadata
        if not self.clip.isEmpty:
            try:
                file = taglib.File(self.clip.path)
                self.__audioMetadata = file.tags
                self.__soundSnapshot = str(self.getMetadataProperty("ZYNTHBOX_SOUND_SNAPSHOT", self.__soundSnapshot))
                self.__adsrAttack = float(self.getMetadataProperty("ZYNTHBOX_ADSR_ATTACK", self.__adsrAttack))
                self.__adsrDecay = float(self.getMetadataProperty("ZYNTHBOX_ADSR_DECAY", self.__adsrDecay))
                self.__adsrRelease = float(self.getMetadataProperty("ZYNTHBOX_ADSR_RELEASE", self.__adsrRelease))
                self.__adsrSustain = float(self.getMetadataProperty("ZYNTHBOX_ADSR_SUSTAIN", self.__adsrSustain))
                self.__audioType = str(self.getMetadataProperty("ZYNTHBOX_AUDIO_TYPE", self.__audioType))
                self.__audioTypeSettings = str(self.getMetadataProperty("ZYNTHBOX_AUDIOTYPESETTINGS", self.__audioTypeSettings))
                self.__bpm = int(self.getMetadataProperty("ZYNTHBOX_BPM", self.__bpm))
                self.__gain = float(self.getMetadataProperty("ZYNTHBOX_GAIN", self.__gain))
                self.__graineratorEnabled = str(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_ENABLED", self.__graineratorEnabled)).lower() == "true"
                self.__graineratorInterval = float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_INTERVAL", self.__graineratorInterval))
                self.__graineratorIntervalAdditional = float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_INTERVAL_ADDITIONAL", self.__graineratorIntervalAdditional))
                self.__graineratorPanMaximum = float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_PAN_MAXIMUM", self.__graineratorPanMaximum))
                self.__graineratorPanMinimum = float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_PAN_MINIMUM", self.__graineratorPanMinimum))
                self.__graineratorPitchMaximum1 = float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_PITCH_MAXIMUM1", self.__graineratorPitchMaximum1))
                self.__graineratorPitchMaximum2 = float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_PITCH_MAXIMUM2", self.__graineratorPitchMaximum2))
                self.__graineratorPitchMinimum1 = float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_PITCH_MINIMUM1", self.__graineratorPitchMinimum1))
                self.__graineratorPitchMinimum2 = float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_PITCH_MINIMUM2", self.__graineratorPitchMinimum2))
                self.__graineratorPitchPriority = float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_PITCH_PRIORITY", self.__graineratorPitchPriority))
                self.__graineratorPosition = float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_POSITION", self.__graineratorPosition))
                self.__graineratorScan = float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_SCAN", self.__graineratorScan))
                self.__graineratorSize = float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_SIZE", self.__graineratorSize))
                self.__graineratorSizeAdditional = float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_SIZE_ADDITIONAL", self.__graineratorSizeAdditional))
                self.__graineratorSpray = float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_SPRAY", self.__graineratorSpray))
                self.__graineratorSustain = float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_SUSTAIN", self.__graineratorSustain))
                self.__graineratorTilt = float(self.getMetadataProperty("ZYNTHBOX_GRAINERATOR_TILT", self.__graineratorTilt))
                self.__length = float(self.getMetadataProperty("ZYNTHBOX_LENGTH", self.__length))
                self.__loopdelta = float(self.getMetadataProperty("ZYNTHBOX_LOOPDELTA", self.__loopdelta))
                self.__loopdelta2 = float(self.getMetadataProperty("ZYNTHBOX_LOOPDELTA2", self.__loopdelta2))
                self.__midiRecording = str(self.getMetadataProperty("ZYNTHBOX_MIDI_RECORDING", self.__midiRecording))
                self.__patternJson = str(self.getMetadataProperty("ZYNTHBOX_PATTERN_JSON", self.__patternJson))
                self.__pitch = float(self.getMetadataProperty("ZYNTHBOX_PITCH", self.__pitch))
                self.__playbackStyle = str(self.getMetadataProperty("ZYNTHBOX_PLAYBACK_STYLE", self.__playbackStyle))
                self.__routingStyle = str(self.getMetadataProperty("ZYNTHBOX_ROUTING_STYLE", self.__routingStyle))
                self.__samplePickingStyle = str(self.getMetadataProperty("ZYNTHBOX_SAMPLE_PICKING_STYLE", self.__samplePickingStyle))
                self.__samples = str(self.getMetadataProperty("ZYNTHBOX_SAMPLES", self.__samples))
                self.__snapLengthToBeat = str(self.getMetadataProperty("ZYNTHBOX_SNAP_LENGTH_TO_BEAT", self.__snapLengthToBeat)).lower() == "true"
                self.__speedRatio = float(self.getMetadataProperty("ZYNTHBOX_SPEED_RATIO", self.__speedRatio))
                self.__startPosition = float(self.getMetadataProperty("ZYNTHBOX_STARTPOSITION", self.__startPosition))
                self.__syncSpeedToBpm = str(self.getMetadataProperty("ZYNTHBOX_SYNC_SPEED_TO_BPM", self.__syncSpeedToBpm)).lower() == "true"
                file.close()
            except Exception as e:
                logging.error(f"Error while trying to read metadata from sketch : {e}")

    def writeMetadata(self):
        # TODO : Make sure default values of dynamic props like audioType, audioTypeSettings are updated when writing metadata
        if not self.clip.isEmpty:
            file = taglib.File(self.clip.path)
            file.tags["ZYNTHBOX_SOUND_SNAPSHOT"] = [str(self.__soundSnapshot)]
            file.tags["ZYNTHBOX_ADSR_ATTACK"] = [str(self.__adsrAttack)]
            file.tags["ZYNTHBOX_ADSR_DECAY"] = [str(self.__adsrDecay)]
            file.tags["ZYNTHBOX_ADSR_RELEASE"] = [str(self.__adsrRelease)]
            file.tags["ZYNTHBOX_ADSR_SUSTAIN"] = [str(self.__adsrSustain)]
            file.tags["ZYNTHBOX_AUDIO_TYPE"] = [str(self.__audioType)]
            file.tags["ZYNTHBOX_AUDIOTYPESETTINGS"] = [str(self.__audioTypeSettings)]
            file.tags["ZYNTHBOX_BPM"] = [str(self.__bpm)]
            file.tags["ZYNTHBOX_GAIN"] = [str(self.__gain)]
            file.tags["ZYNTHBOX_GRAINERATOR_ENABLED"] = [str(self.__graineratorEnabled)]
            file.tags["ZYNTHBOX_GRAINERATOR_INTERVAL"] = [str(self.__graineratorInterval)]
            file.tags["ZYNTHBOX_GRAINERATOR_INTERVAL_ADDITIONAL"] = [str(self.__graineratorIntervalAdditional)]
            file.tags["ZYNTHBOX_GRAINERATOR_PAN_MAXIMUM"] = [str(self.__graineratorPanMaximum)]
            file.tags["ZYNTHBOX_GRAINERATOR_PAN_MINIMUM"] = [str(self.__graineratorPanMinimum)]
            file.tags["ZYNTHBOX_GRAINERATOR_PITCH_MAXIMUM1"] = [str(self.__graineratorPitchMaximum1)]
            file.tags["ZYNTHBOX_GRAINERATOR_PITCH_MAXIMUM2"] = [str(self.__graineratorPitchMaximum2)]
            file.tags["ZYNTHBOX_GRAINERATOR_PITCH_MINIMUM1"] = [str(self.__graineratorPitchMinimum1)]
            file.tags["ZYNTHBOX_GRAINERATOR_PITCH_MINIMUM2"] = [str(self.__graineratorPitchMinimum2)]
            file.tags["ZYNTHBOX_GRAINERATOR_PITCH_PRIORITY"] = [str(self.__graineratorPitchPriority)]
            file.tags["ZYNTHBOX_GRAINERATOR_POSITION"] = [str(self.__graineratorPosition)]
            file.tags["ZYNTHBOX_GRAINERATOR_SCAN"] = [str(self.__graineratorScan)]
            file.tags["ZYNTHBOX_GRAINERATOR_SIZE"] = [str(self.__graineratorSize)]
            file.tags["ZYNTHBOX_GRAINERATOR_SIZE_ADDITIONAL"] = [str(self.__graineratorSizeAdditional)]
            file.tags["ZYNTHBOX_GRAINERATOR_SPRAY"] = [str(self.__graineratorSpray)]
            file.tags["ZYNTHBOX_GRAINERATOR_SUSTAIN"] = [str(self.__graineratorSustain)]
            file.tags["ZYNTHBOX_GRAINERATOR_TILT"] = [str(self.__graineratorTilt)]
            file.tags["ZYNTHBOX_LENGTH"] = [str(self.__length)]
            file.tags["ZYNTHBOX_LOOPDELTA"] = [str(self.__loopdelta)]
            file.tags["ZYNTHBOX_LOOPDELTA2"] = [str(self.__loopdelta2)]
            file.tags["ZYNTHBOX_MIDI_RECORDING"] = [str(self.__midiRecording)]
            file.tags["ZYNTHBOX_PATTERN_JSON"] = [str(self.__patternJson)]
            file.tags["ZYNTHBOX_PITCH"] = [str(self.__pitch)]
            file.tags["ZYNTHBOX_PLAYBACK_STYLE"] = [str(self.__playbackStyle)]
            file.tags["ZYNTHBOX_ROUTING_STYLE"] = [str(self.__routingStyle)]
            file.tags["ZYNTHBOX_SAMPLE_PICKING_STYLE"] = [str(self.__samplePickingStyle)]
            file.tags["ZYNTHBOX_SAMPLES"] = [str(self.__samples)]
            file.tags["ZYNTHBOX_SNAP_LENGTH_TO_BEAT"] = [str(self.__snapLengthToBeat)]
            file.tags["ZYNTHBOX_SPEED_RATIO"] = [str(self.__speedRatio)]
            file.tags["ZYNTHBOX_STARTPOSITION"] = [str(self.__startPosition)]
            file.tags["ZYNTHBOX_SYNC_SPEED_TO_BPM"] = [str(self.__syncSpeedToBpm)]
            file.save()

    def get_soundSnapshot(self):
        return self.__soundSnapshot
    def get_adsrAttack(self):
        return self.__adsrAttack
    def get_adsrDecay(self):
        return self.__adsrDecay
    def get_adsrRelease(self):
        return self.__adsrRelease
    def get_adsrSustain(self):
        return self.__adsrSustain
    def get_audioType(self):
        return self.__audioType
    def get_audioTypeSettings(self):
        return self.__audioTypeSettings
    def get_bpm(self):
        return self.__bpm
    def get_gain(self):
        return self.__gain
    def get_graineratorEnabled(self):
        return self.__graineratorEnabled
    def get_graineratorInterval(self):
        return self.__graineratorInterval
    def get_graineratorIntervalAdditional(self):
        return self.__graineratorIntervalAdditional
    def get_graineratorPanMaximum(self):
        return self.__graineratorPanMaximum
    def get_graineratorPanMinimum(self):
        return self.__graineratorPanMinimum
    def get_graineratorPitchMaximum1(self):
        return self.__graineratorPitchMaximum1
    def get_graineratorPitchMaximum2(self):
        return self.__graineratorPitchMaximum2
    def get_graineratorPitchMinimum1(self):
        return self.__graineratorPitchMinimum1
    def get_graineratorPitchMinimum2(self):
        return self.__graineratorPitchMinimum2
    def get_graineratorPitchPriority(self):
        return self.__graineratorPitchPriority
    def get_graineratorPosition(self):
        return self.__graineratorPosition
    def get_graineratorScan(self):
        return self.__graineratorScan
    def get_graineratorSize(self):
        return self.__graineratorSize
    def get_graineratorSizeAdditional(self):
        return self.__graineratorSizeAdditional
    def get_graineratorSpray(self):
        return self.__graineratorSpray
    def get_graineratorSustain(self):
        return self.__graineratorSustain
    def get_graineratorTilt(self):
        return self.__graineratorTilt
    def get_length(self):
        return self.__length
    def get_loopdelta(self):
        return self.__loopdelta
    def get_loopdelta2(self):
        return self.__loopdelta2
    def get_midiRecording(self):
        return self.__midiRecording
    def get_patternJson(self):
        return self.__patternJson
    def get_pitch(self):
        return self.__pitch
    def get_playbackStyle(self):
        return self.__playbackStyle
    def get_routingStyle(self):
        return self.__routingStyle
    def get_samplePickingStyle(self):
        return self.__samplePickingStyle
    def get_samples(self):
        return self.__samples
    def get_snapLengthToBeat(self):
        return self.__snapLengthToBeat
    def get_speedRatio(self):
        return self.__speedRatio
    def get_startPosition(self):
        return self.__startPosition
    def get_syncSpeedToBpm(self):
        return self.__syncSpeedToBpm

    def set_soundSnapshot(self, value, force=False):
        if value != self.__soundSnapshot or force:
            self.__soundSnapshot = value
            self.soundSnapshotChanged.emit()
            self.saveMetadata()
    def set_adsrAttack(self, value, force=False):
        if value != self.__adsrAttack or force:
            self.__adsrAttack = value
            self.adsrAttackChanged.emit()
            self.saveMetadata()
    def set_adsrDecay(self, value, force=False):
        if value != self.__adsrDecay or force:
            self.__adsrDecay = value
            self.adsrDecayChanged.emit()
            self.saveMetadata()
    def set_adsrRelease(self, value, force=False):
        if value != self.__adsrRelease or force:
            self.__adsrRelease = value
            self.adsrReleaseChanged.emit()
            self.saveMetadata()
    def set_adsrSustain(self, value, force=False):
        if value != self.__adsrSustain or force:
            self.__adsrSustain = value
            self.adsrSustainChanged.emit()
            self.saveMetadata()
    def set_audioType(self, value, force=False):
        if value != self.__audioType or force:
            self.__audioType = value
            self.audioTypeChanged.emit()
            self.saveMetadata()
    def set_audioTypeSettings(self, value, force=False):
        if value != self.__audioTypeSettings or force:
            self.__audioTypeSettings = value
            self.audioTypeSettingsChanged.emit()
            self.saveMetadata()
    def set_bpm(self, value, force=False):
        if value != self.__bpm or force:
            self.__bpm = value
            self.bpmChanged.emit()
            self.saveMetadata()
    def set_gain(self, value, force=False):
        if value != self.__gain or force:
            self.__gain = value
            self.gainChanged.emit()
            self.saveMetadata()
    def set_graineratorEnabled(self, value, force=False):
        if value != self.__graineratorEnabled or force:
            self.__graineratorEnabled = value
            self.graineratorEnabledChanged.emit()
            self.saveMetadata()
    def set_graineratorInterval(self, value, force=False):
        if value != self.__graineratorInterval or force:
            self.__graineratorInterval = value
            self.graineratorIntervalChanged.emit()
            self.saveMetadata()
    def set_graineratorIntervalAdditional(self, value, force=False):
        if value != self.__graineratorIntervalAdditional or force:
            self.__graineratorIntervalAdditional = value
            self.graineratorIntervalAdditionalChanged.emit()
            self.saveMetadata()
    def set_graineratorPanMaximum(self, value, force=False):
        if value != self.__graineratorPanMaximum or force:
            self.__graineratorPanMaximum = value
            self.graineratorPanMaximumChanged.emit()
            self.saveMetadata()
    def set_graineratorPanMinimum(self, value, force=False):
        if value != self.__graineratorPanMinimum or force:
            self.__graineratorPanMinimum = value
            self.graineratorPanMinimumChanged.emit()
            self.saveMetadata()
    def set_graineratorPitchMaximum1(self, value, force=False):
        if value != self.__graineratorPitchMaximum1 or force:
            self.__graineratorPitchMaximum1 = value
            self.graineratorPitchMaximum1Changed.emit()
            self.saveMetadata()
    def set_graineratorPitchMaximum2(self, value, force=False):
        if value != self.__graineratorPitchMaximum2 or force:
            self.__graineratorPitchMaximum2 = value
            self.graineratorPitchMaximum2Changed.emit()
            self.saveMetadata()
    def set_graineratorPitchMinimum1(self, value, force=False):
        if value != self.__graineratorPitchMinimum1 or force:
            self.__graineratorPitchMinimum1 = value
            self.graineratorPitchMinimum1Changed.emit()
            self.saveMetadata()
    def set_graineratorPitchMinimum2(self, value, force=False):
        if value != self.__graineratorPitchMinimum2 or force:
            self.__graineratorPitchMinimum2 = value
            self.graineratorPitchMinimum2Changed.emit()
            self.saveMetadata()
    def set_graineratorPitchPriority(self, value, force=False):
        if value != self.__graineratorPitchPriority or force:
            self.__graineratorPitchPriority = value
            self.graineratorPitchPriorityChanged.emit()
            self.saveMetadata()
    def set_graineratorPosition(self, value, force=False):
        if value != self.__graineratorPosition or force:
            self.__graineratorPosition = value
            self.graineratorPositionChanged.emit()
            self.saveMetadata()
    def set_graineratorScan(self, value, force=False):
        if value != self.__graineratorScan or force:
            self.__graineratorScan = value
            self.graineratorScanChanged.emit()
            self.saveMetadata()
    def set_graineratorSize(self, value, force=False):
        if value != self.__graineratorSize or force:
            self.__graineratorSize = value
            self.graineratorSizeChanged.emit()
            self.saveMetadata()
    def set_graineratorSizeAdditional(self, value, force=False):
        if value != self.__graineratorSizeAdditional or force:
            self.__graineratorSizeAdditional = value
            self.graineratorSizeAdditionalChanged.emit()
            self.saveMetadata()
    def set_graineratorSpray(self, value, force=False):
        if value != self.__graineratorSpray or force:
            self.__graineratorSpray = value
            self.graineratorSprayChanged.emit()
            self.saveMetadata()
    def set_graineratorSustain(self, value, force=False):
        if value != self.__graineratorSustain or force:
            self.__graineratorSustain = value
            self.graineratorSustainChanged.emit()
            self.saveMetadata()
    def set_graineratorTilt(self, value, force=False):
        if value != self.__graineratorTilt or force:
            self.__graineratorTilt = value
            self.graineratorTiltChanged.emit()
            self.saveMetadata()
    def set_length(self, value, force=False):
        if value != self.__length or force:
            self.__length = value
            self.lengthChanged.emit()
            self.saveMetadata()
    def set_loopdelta(self, value, force=False):
        if value != self.__loopdelta or force:
            self.__loopdelta = value
            self.loopdeltaChanged.emit()
            self.saveMetadata()
    def set_loopdelta2(self, value, force=False):
        if value != self.__loopdelta2 or force:
            self.__loopdelta2 = value
            self.loopdelta2Changed.emit()
            self.saveMetadata()
    def set_midiRecording(self, value, force=False):
        if value != self.__midiRecording or force:
            self.__midiRecording = value
            self.midiRecordingChanged.emit()
            self.saveMetadata()
    def set_patternJson(self, value, force=False):
        if value != self.__patternJson or force:
            self.__patternJson = value
            self.patternJsonChanged.emit()
            self.saveMetadata()
    def set_pitch(self, value, force=False):
        if value != self.__pitch or force:
            self.__pitch = value
            self.pitchChanged.emit()
            self.saveMetadata()
    def set_playbackStyle(self, value, force=False):
        if value != self.__playbackStyle or force:
            self.__playbackStyle = value
            self.playbackStyleChanged.emit()
            self.saveMetadata()
    def set_routingStyle(self, value, force=False):
        if value != self.__routingStyle or force:
            self.__routingStyle = value
            self.routingStyleChanged.emit()
            self.saveMetadata()
    def set_samplePickingStyle(self, value, force=False):
        if value != self.__samplePickingStyle or force:
            self.__samplePickingStyle = value
            self.samplePickingStyleChanged.emit()
            self.saveMetadata()
    def set_samples(self, value, force=False):
        if value != self.__samples or force:
            self.__samples = value
            self.samplesChanged.emit()
            self.saveMetadata()
    def set_snapLengthToBeat(self, value, force=False):
        if value != self.__snapLengthToBeat or force:
            self.__snapLengthToBeat = value
            self.snapLengthToBeatChanged.emit()
            self.saveMetadata()
    def set_speedRatio(self, value, force=False):
        if value != self.__speedRatio or force:
            self.__speedRatio = value
            self.speedRatioChanged.emit()
            self.saveMetadata()
    def set_startPosition(self, value, force=False):
        if value != self.__startPosition or force:
            self.__startPosition = value
            self.startPositionChanged.emit()
            self.saveMetadata()
    def set_syncSpeedToBpm(self, value, force=False):
        if value != self.__syncSpeedToBpm or force:
            self.__syncSpeedToBpm = value
            self.syncSpeedToBpmChanged.emit()
            self.saveMetadata()

    soundSnapshotChanged = Signal()
    adsrAttackChanged = Signal()
    adsrDecayChanged = Signal()
    adsrReleaseChanged = Signal()
    adsrSustainChanged = Signal()
    audioTypeChanged = Signal()
    audioTypeSettingsChanged = Signal()
    bpmChanged = Signal()
    gainChanged = Signal()
    graineratorEnabledChanged = Signal()
    graineratorIntervalChanged = Signal()
    graineratorIntervalAdditionalChanged = Signal()
    graineratorPanMaximumChanged = Signal()
    graineratorPanMinimumChanged = Signal()
    graineratorPitchMaximum1Changed = Signal()
    graineratorPitchMaximum2Changed = Signal()
    graineratorPitchMinimum1Changed = Signal()
    graineratorPitchMinimum2Changed = Signal()
    graineratorPitchPriorityChanged = Signal()
    graineratorPositionChanged = Signal()
    graineratorScanChanged = Signal()
    graineratorSizeChanged = Signal()
    graineratorSizeAdditionalChanged = Signal()
    graineratorSprayChanged = Signal()
    graineratorSustainChanged = Signal()
    graineratorTiltChanged = Signal()
    lengthChanged = Signal()
    loopdeltaChanged = Signal()
    loopdelta2Changed = Signal()
    midiRecordingChanged = Signal()
    patternJsonChanged = Signal()
    pitchChanged = Signal()
    playbackStyleChanged = Signal()
    routingStyleChanged = Signal()
    samplePickingStyleChanged = Signal()
    samplesChanged = Signal()
    snapLengthToBeatChanged = Signal()
    speedRatioChanged = Signal()
    startPositionChanged = Signal()
    syncSpeedToBpmChanged = Signal()

    soundSnapshot = Property(str, get_soundSnapshot, set_soundSnapshot, notify=soundSnapshotChanged)
    adsrAttack = Property(float, get_adsrAttack, set_adsrAttack, notify=adsrAttackChanged)
    adsrDecay = Property(float, get_adsrDecay, set_adsrDecay, notify=adsrDecayChanged)
    adsrRelease = Property(float, get_adsrRelease, set_adsrRelease, notify=adsrReleaseChanged)
    adsrSustain = Property(float, get_adsrSustain, set_adsrSustain, notify=adsrSustainChanged)
    audioType = Property(str, get_audioType, set_audioType, notify=audioTypeChanged)
    audioTypeSettings = Property(str, get_audioTypeSettings, set_audioTypeSettings, notify=audioTypeSettingsChanged)
    bpm = Property(int, get_bpm, set_bpm, notify=bpmChanged)
    gain = Property(float, get_gain, set_gain, notify=gainChanged)
    graineratorEnabled = Property(bool, get_graineratorEnabled, set_graineratorEnabled, notify=graineratorEnabledChanged)
    graineratorInterval = Property(float, get_graineratorInterval, set_graineratorInterval, notify=graineratorIntervalChanged)
    graineratorIntervalAdditional = Property(int, get_graineratorIntervalAdditional, set_graineratorIntervalAdditional, notify=graineratorIntervalAdditionalChanged)
    graineratorPanMaximum = Property(float, get_graineratorPanMaximum, set_graineratorPanMaximum, notify=graineratorPanMaximumChanged)
    graineratorPanMinimum = Property(float, get_graineratorPanMinimum, set_graineratorPanMinimum, notify=graineratorPanMinimumChanged)
    graineratorPitchMaximum1 = Property(float, get_graineratorPitchMaximum1, set_graineratorPitchMaximum1, notify=graineratorPitchMaximum1Changed)
    graineratorPitchMaximum2 = Property(float, get_graineratorPitchMaximum2, set_graineratorPitchMaximum2, notify=graineratorPitchMaximum2Changed)
    graineratorPitchMinimum1 = Property(float, get_graineratorPitchMinimum1, set_graineratorPitchMinimum1, notify=graineratorPitchMinimum1Changed)
    graineratorPitchMinimum2 = Property(float, get_graineratorPitchMinimum2, set_graineratorPitchMinimum2, notify=graineratorPitchMinimum2Changed)
    graineratorPitchPriority = Property(float, get_graineratorPitchPriority, set_graineratorPitchPriority, notify=graineratorPitchPriorityChanged)
    graineratorPosition = Property(float, get_graineratorPosition, set_graineratorPosition, notify=graineratorPositionChanged)
    graineratorScan = Property(float, get_graineratorScan, set_graineratorScan, notify=graineratorScanChanged)
    graineratorSize = Property(float, get_graineratorSize, set_graineratorSize, notify=graineratorSizeChanged)
    graineratorSizeAdditional = Property(float, get_graineratorSizeAdditional, set_graineratorSizeAdditional, notify=graineratorSizeAdditionalChanged)
    graineratorSpray = Property(float, get_graineratorSpray, set_graineratorSpray, notify=graineratorSprayChanged)
    graineratorSustain = Property(float, get_graineratorSustain, set_graineratorSustain, notify=graineratorSustainChanged)
    graineratorTilt = Property(float, get_graineratorTilt, set_graineratorTilt, notify=graineratorTiltChanged)
    length = Property(float, get_length, set_length, notify=lengthChanged)
    loopdelta = Property(float, get_loopdelta, set_loopdelta, notify=loopdeltaChanged)
    loopdelta2 = Property(float, get_loopdelta2, set_loopdelta2, notify=loopdelta2Changed)
    midiRecording = Property(str, get_midiRecording, set_midiRecording, notify=midiRecordingChanged)
    patternJson = Property(str, get_patternJson, set_patternJson, notify=patternJsonChanged)
    pitch = Property(float, get_pitch, set_pitch, notify=pitchChanged)
    playbackStyle = Property(str, get_playbackStyle, set_playbackStyle, notify=playbackStyleChanged)
    routingStyle = Property(str, get_routingStyle, set_routingStyle, notify=routingStyleChanged)
    samplePickingStyle = Property(str, get_samplePickingStyle, set_samplePickingStyle, notify=samplePickingStyleChanged)
    samples = Property(str, get_samples, set_samples, notify=samplesChanged)
    snapLengthToBeat = Property(bool, get_snapLengthToBeat, set_snapLengthToBeat, notify=snapLengthToBeatChanged)
    speedRatio = Property(float, get_speedRatio, set_speedRatio, notify=speedRatioChanged)
    startPosition = Property(float, get_startPosition, set_startPosition, notify=startPositionChanged)
    syncSpeedToBpm = Property(bool, get_syncSpeedToBpm, set_syncSpeedToBpm, notify=syncSpeedToBpmChanged)


class sketchpad_clip(QObject):
    def __init__(self, row_index: int, col_index: int, part_index: int, song: QObject, parent=None, is_channel_sample=False):
        super(sketchpad_clip, self).__init__(parent)
        self.zynqtgui = zynthian_gui_config.zynqtgui

        self.is_channel_sample = is_channel_sample
        self.__row_index__ = row_index
        self.__col_index__ = col_index
        self.__part_index__ = part_index
        self.__path__ = None
        self.__filename__ = ""
        self.__song__ = song
        self.__initial_length__ = 4
        self.__initial_start_position__ = 0.0
        self.__initial_pitch__ = 0
        self.__initial_speed_ratio = 1
        self.__speed_ratio__ = self.__initial_speed_ratio
        self.__initial_gain__ = 0
        self.__progress__ = 0.0
        self.__audio_level__ = -200
        self.audioSource = None
        self.recording_basepath = song.sketchpad_folder
        self.wav_path = Path(self.__song__.sketchpad_folder) / 'wav'
        self.__slices__ = 16
        self.__enabled__ = False
        self.channel = None
        self.__lane__ = part_index
        self.__metadata = sketchpad_clip_metadata(self)

        # Just in case, fix up the lane so it's something sensible (we have five lanes, so...)
        if self.__lane__ < 0 or self.__lane__ > 4:
            self.__lane__ = 0

        self.__autoStopTimer__ = QTimer()
        self.__autoStopTimer__.setSingleShot(True)
        self.__autoStopTimer__.timeout.connect(self.stop_audio)

        self.__update_synced_values_throttle = QTimer()
        self.__update_synced_values_throttle.setSingleShot(True)
        self.__update_synced_values_throttle.setInterval(50)
        self.__update_synced_values_throttle.timeout.connect(self.update_synced_values_actual, Qt.QueuedConnection)
        Zynthbox.SyncTimer.instance().bpmChanged.connect(self.update_synced_values, Qt.QueuedConnection)
        self.bpm_changed.connect(self.update_synced_values, Qt.QueuedConnection)

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

        self.saveMetadataTimer = QTimer()
        self.saveMetadataTimer.setInterval(1000)
        self.saveMetadataTimer.setSingleShot(True)
        self.saveMetadataTimer.timeout.connect(self.doSaveMetadata)

        self.path_changed.connect(self.zynqtgui.zynautoconnect_audio)

    # A helper method to generate unique name when copying a wave file into a folder
    # Arg file : Full Path of file to be copied
    # Arg copy_dir : Full Path of destination dir where the file will be copied
    # Returns : An unique filename as string in the format f"{file_basename}-{counter}.{category}.wav" (where category is either "clip" or "sketch")
    @staticmethod
    def generate_unique_filename(file, copy_dir):
        file_path = Path(file)
        copy_dir_path = Path(copy_dir)
        counter = 1

        # Find the base filename excluding our suffix (sketch.wav)
        categoryPrefix = "sketch"
        file_basename = file_path.name.split(".wav")[0].split(f".{categoryPrefix}")[0]
        # Remove the `counter` part from the string if exists
        file_basename = re.sub('-\d*$', '', file_basename)

        if not (copy_dir_path / f"{file_basename}.{categoryPrefix}.wav").exists():
            return f"{file_basename}.{categoryPrefix}.wav"
        else:
            while Path(copy_dir_path / f"{file_basename}-{counter}.{categoryPrefix}.wav").exists():
                counter += 1

            return f"{file_basename}-{counter}.{categoryPrefix}.wav"

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

    @Slot(int)
    def setVolume(self, vol):
        if self.audioSource is not None:
            self.audioSource.setVolume(vol)

    def update_synced_values(self):
        self.__update_synced_values_throttle.start()

    def update_synced_values_actual(self):
        if self.metadataSyncSpeedToBpm:
            new_ratio = Zynthbox.SyncTimer.instance().getBpm() / self.metadataBPM
            logging.info(f"Song BPM : {Zynthbox.SyncTimer.instance().getBpm()} - Sample BPM: {self.metadataBPM} - New Speed Ratio : {new_ratio}")
            self.set_speedRatio(new_ratio, True)

            # if self.__start_position_before_sync__ is not None:
            #     self.startPosition = new_ratio * self.__start_position__

        # Set length to recalculate loop time
        self.set_length(self.__length__, True)
        self.sec_per_beat_changed.emit()

    def serialize(self):
        return {
            "path": self.__path__,
            "enabled": self.__enabled__
        }

    def deserialize(self, obj):
        try:
            if "path" in obj:
                if obj["path"] is None:
                    self.__path__ = None
                else:
                    if self.is_channel_sample:
                        self.set_path(str(self.bank_path / obj["path"]), False)
                    else:
                        self.set_path(str(self.wav_path / obj["path"]), False)
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


    def part(self):
        return self.__part_index__
    def set_part(self, index):
        if self.__part_index__ != index:
            self.__part_index__ = index
            self.part_index_changed.emit()
    part_index_changed = Signal()
    part = Property(int, part, set_part, notify=part_index_changed)

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
        return f"{self.get_channel_name()}-{self.get_part_name()}"
    name = Property(str, name, constant=True)


    def get_part_name(self):
        return chr(self.__col_index__+65)
        # if self.__col_index__ == 0:
        #     return "I"
        # elif self.__col_index__ == 1:
        #     return "II"
        # else:
        #     return ""
    partName = Property(str, get_part_name, constant=True)

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
    def set_path(self, path, should_copy=True):
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

        if self.audioSource is not None:
            try: self.audioSource.isPlayingChanged.disconnect(self.is_playing_changed.emit)
            except: pass
            try: self.audioSource.audioLevelChanged.disconnect()
            except: pass
            try: self.audioSource.progressChanged.disconnect()
            except: pass
            try: self.audioSource.gainAbsoluteChanged.disconnect()
            except: pass
            try: self.audioSource.playbackStyleChanged.disconnect()
            except: pass
            self.audioSource.deleteLater()

        self.zynqtgui.currentTaskMessage = f"Loading Sketchpad : Loading Sample<br/>{self.__filename__}"
        if path is not None:
            self.audioSource = Zynthbox.ClipAudioSource(path, False, self)
            self.audioSource.isPlayingChanged.connect(self.is_playing_changed.emit)
            self.audioSource.setLaneAffinity(self.__lane__)
            if self.clipChannel is not None and self.__song__.isLoading == False:
                self.clipChannel.trackType = "sample-loop"
            self.cppObjIdChanged.emit()
        else:
            self.audioSource = None

        self.__read_metadata__()

        playbackStyle = str(self.__get_metadata_prop__("ZYNTHBOX_PLAYBACK_STYLE", ""))
        if self.audioSource is not None:
            if playbackStyle == "":
                # TODO Probably get rid of this at some point - it's a temporary fallback while there's reasonably still things around without playback style set on them
                looping = bool(self.__get_metadata_prop__("ZYNTHBOX_LOOPING_PLAYBACK", True))
                granular = (self.__get_metadata_prop__("ZYNTHBOX_GRAINERATOR_ENABLED", 'False').lower() == "true")
                if looping:
                    if granular:
                        self.audioSource.setPlaybackStyle(Zynthbox.ClipAudioSource.PlaybackStyle.GranularLoopingPlaybackStyle)
                    else:
                        self.audioSource.setPlaybackStyle(Zynthbox.ClipAudioSource.PlaybackStyle.LoopingPlaybackStyle)
                elif looping:
                    if granular:
                        self.audioSource.setPlaybackStyle(Zynthbox.ClipAudioSource.PlaybackStyle.GranularNonLoopingPlaybackStyle)
                    else:
                        self.audioSource.setPlaybackStyle(Zynthbox.ClipAudioSource.PlaybackStyle.NonLoopingPlaybackStyle)
            else:
                if playbackStyle.startswith("Zynthbox.ClipAudioSource.PlaybackStyle."):
                    playbackStyle = playbackStyle.split(".")[-1]
                if playbackStyle in Zynthbox.ClipAudioSource.PlaybackStyle.values:
                    self.audioSource.setPlaybackStyle(Zynthbox.ClipAudioSource.PlaybackStyle.values[playbackStyle])
                else:
                    self.audioSource.setPlaybackStyle(Zynthbox.ClipAudioSource.PlaybackStyle.LoopingPlaybackStyle)

        self.__length__ = float(self.__get_metadata_prop__("ZYNTHBOX_LENGTH", self.__initial_length__))
        self.__start_position__ = float(self.__get_metadata_prop__("ZYNTHBOX_STARTPOSITION", self.__initial_start_position__))
        self.__loop_delta__ = float(self.__get_metadata_prop__("ZYNTHBOX_LOOPDELTA", 0.0))
        self.__pitch__ = int(self.__get_metadata_prop__("ZYNTHBOX_PITCH", self.__initial_pitch__))
        self.__speed_ratio__ = float(self.__get_metadata_prop__("ZYNTHBOX_SPEED_RATIO", self.__initial_speed_ratio))
        self.__gain__ = float(self.__get_metadata_prop__("ZYNTHBOX_GAIN", self.__initial_gain__))
        self.__progress__ = 0.0
        self.__audio_level__ = -200
        self.__snap_length_to_beat__ = (self.__get_metadata_prop__("ZYNTHBOX_SNAP_LENGTH_TO_BEAT", 'True').lower() == "true")
        if self.audioSource is not None:
            self.audioSource.setLoopDelta(self.__loop_delta__)
            self.audioSource.setADSRAttack(float(self.__get_metadata_prop__("ZYNTHBOX_ADSR_ATTACK", 0)))
            self.audioSource.setADSRDecay(float(self.__get_metadata_prop__("ZYNTHBOX_ADSR_DECAY", 0)))
            self.audioSource.setADSRSustain(float(self.__get_metadata_prop__("ZYNTHBOX_ADSR_SUSTAIN", 1)))
            self.audioSource.setADSRRelease(float(self.__get_metadata_prop__("ZYNTHBOX_ADSR_RELEASE", 0.05)))
            self.audioSource.setGrainPosition(float(self.__get_metadata_prop__("ZYNTHBOX_GRAINERATOR_POSITION", 0)))
            self.audioSource.setGrainSpray(float(self.__get_metadata_prop__("ZYNTHBOX_GRAINERATOR_SPRAY", 1)))
            self.audioSource.setGrainScan(float(self.__get_metadata_prop__("ZYNTHBOX_GRAINERATOR_SCAN", 0)))
            self.audioSource.setGrainInterval(float(self.__get_metadata_prop__("ZYNTHBOX_GRAINERATOR_INTERVAL", 10)))
            self.audioSource.setGrainIntervalAdditional(float(self.__get_metadata_prop__("ZYNTHBOX_GRAINERATOR_INTERVAL_ADDITIONAL", 10)))
            self.audioSource.setGrainSize(float(self.__get_metadata_prop__("ZYNTHBOX_GRAINERATOR_SIZE", 100)))
            self.audioSource.setGrainSizeAdditional(float(self.__get_metadata_prop__("ZYNTHBOX_GRAINERATOR_SIZE_ADDITIONAL", 50)))
            self.audioSource.setGrainPanMinimum(float(self.__get_metadata_prop__("ZYNTHBOX_GRAINERATOR_PAN_MINIMUM", -1)))
            self.audioSource.setGrainPanMaximum(float(self.__get_metadata_prop__("ZYNTHBOX_GRAINERATOR_PAN_MAXIMUM", 1)))
            self.audioSource.setGrainSustain(float(self.__get_metadata_prop__("ZYNTHBOX_GRAINERATOR_SUSTAIN", 0.3)))
            self.audioSource.setGrainTilt(float(self.__get_metadata_prop__("ZYNTHBOX_GRAINERATOR_TILT", 0.5)))
            self.audioSource.setGrainPitchMinimum1(float(self.__get_metadata_prop__("ZYNTHBOX_GRAINERATOR_PITCH_MINIMUM1", 1.0)))
            self.audioSource.setGrainPitchMaximum1(float(self.__get_metadata_prop__("ZYNTHBOX_GRAINERATOR_PITCH_MAXIMUM1", 1.0)))
            self.audioSource.setGrainPitchMinimum2(float(self.__get_metadata_prop__("ZYNTHBOX_GRAINERATOR_PITCH_MINIMUM2", 1.0)))
            self.audioSource.setGrainPitchMaximum2(float(self.__get_metadata_prop__("ZYNTHBOX_GRAINERATOR_PITCH_MAXIMUM2", 1.0)))
            self.audioSource.setGrainPitchPriority(float(self.__get_metadata_prop__("ZYNTHBOX_GRAINERATOR_PITCH_PRIORITY", 0.5)))
            self.audioSource.progressChanged.connect(self.progress_changed_cb, Qt.QueuedConnection)
            self.audioSource.gainAbsoluteChanged.connect(self.updateGain, Qt.QueuedConnection)
            self.audioSource.playbackStyleChanged.connect(self.saveMetadata, Qt.QueuedConnection)

        self.set_length(self.__length__, True)
        self.set_start_position(self.__start_position__, True)
        self.set_loop_delta(self.__loop_delta__, True)
        self.set_speedRatio(self.__speed_ratio__, True)
        self.set_pitch(self.__pitch__, True)
        self.set_gain(self.__gain__, True)
        self.set_snap_length_to_beat(self.__snap_length_to_beat__, True)
        self.update_synced_values()

        self.path_changed.emit()
        self.__read_metadata__()
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

    @Signal
    def audioLevelChanged(self):
        pass

    def get_audioLevel(self):
        if self.isPlaying:
            return self.__audio_level__
        else:
            return -200

    audioLevel = Property(float, get_audioLevel, notify=audioLevelChanged)

    @Slot(None)
    def clear(self, loop=True):
        self.stop()

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
            # We will now allow playing multiple parts of a sample-loop channel and hence do not stop other clips in part when playing
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
            # logging.info(f"Setting Clip To Play from the beginning at the top of the next bar {self} track {self.channel.id} part {self.part}")
            # Until we work out what to actually do with the whole "more than one songs" thing, this will do
            songIndex = 0
            Zynthbox.PlayfieldManager.instance().setClipPlaystate(songIndex, self.channel.id, self.part, Zynthbox.PlayfieldManager.PlaybackState.PlayingState, Zynthbox.PlayfieldManager.PlayfieldStatePosition.NextBarPosition, 0)

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
                # logging.info(f"Setting Clip To Stop from the beginning at the top of the next bar {self} track {self.channel.id} part {self.part}")
                Zynthbox.PlayfieldManager.instance().setClipPlaystate(songIndex, self.channel.id, self.part, Zynthbox.PlayfieldManager.PlaybackState.StoppedState, Zynthbox.PlayfieldManager.PlayfieldStatePosition.NextBarPosition, 0)
            else:
                # logging.info(f"Setting Clip To Stop immediately {self} track {self.channel.id} part {self.part}")
                Zynthbox.PlayfieldManager.instance().setClipPlaystate(songIndex, self.channel.id, self.part, Zynthbox.PlayfieldManager.PlaybackState.StoppedState, Zynthbox.PlayfieldManager.PlayfieldStatePosition.CurrentPosition, 0)

        if self.isPlaying:
            if self.audioSource is not None:
                partObject = self.__song__.partsModel.getPart(self.__col_index__)
                if partObject is not None:
                    partObject.isPlaying = False

    def destroy(self):
        if self.audioSource is not None:
            self.audioSource.deleteLater()

    @Slot(bool)
    def queueRecording(self, do_countin=True):
        return self.__song__.get_metronome_manager().queue_clip_record(self, do_countin)

    @Slot(None)
    def stopRecording(self):
        self.__song__.get_metronome_manager().stopRecording()

    @Signal
    def sound_data_changed(self):
        pass

    def __read_metadata__(self):
        self.audio_metadata = None

        try:
            if self.path is not None:
                self.audio_metadata = taglib.File(self.path).tags
        except:
            pass
        self.sound_data_changed.emit()
        self.metadata_bpm_changed.emit()
        self.metadata_audio_type_changed.emit()
        self.metadata_midi_recording_changed.emit()
        self.metadataSyncSpeedToBpmChanged.emit()
        self.samples_data_changed.emit()

    def write_metadata(self, key, value: list):
        if self.__path__ is not None:
            try:
                file = taglib.File(self.path)
                file.tags[key] = value
                file.save()
            except Exception as e:
                logging.error(f"Error writing metadata : {str(e)}")
                logging.info(f"Trying to create a new file without metadata")

                try:
                    with tempfile.TemporaryDirectory() as tmp:
                        logging.info("Creating new temp file without metadata")
                        logging.debug(f"ffmpeg -i {self.path} -codec copy {Path(tmp) / 'output.wav'}")
                        check_output(f"ffmpeg -i {self.path} -codec copy {Path(tmp) / 'output.wav'}", shell=True)

                        logging.info("Replacing old file")
                        logging.debug(f"mv {Path(tmp) / 'output.wav'} {self.path}")
                        check_output(f"mv {Path(tmp) / 'output.wav'} {self.path}", shell=True)

                        file = taglib.File(self.path)
                        file.tags[key] = value
                        file.save()
                except Exception as e:
                    logging.error(f"Error creating new file and writing metadata : {str(e)}")

            # logging.debug(f"Writing metadata to {self.path} : {key} -> {value}")

        self.__read_metadata__()

    def get_soundData(self):
        data = []

        if self.audio_metadata is not None:
            try:
                jsondata = json.loads(self.audio_metadata["ZYNTHBOX_ACTIVELAYER"][0])
                # data = [f"{jsondata['engine_name']} > {jsondata['preset_name']}"]
                for layer in jsondata["layers"]:
                    data.append(f"{layer['engine_name']} > {layer['preset_name']}")
            except Exception as e:
                # logging.debug(f"Error retrieving from metadata : {str(e)}")
                pass

        return data

    soundData = Property('QVariantList', get_soundData, notify=sound_data_changed)

    ### BEGIN Property sketchContainsSound
    def get_sketchContainsSound(self):
        if self.audio_metadata is not None:
            try:
                jsondata = json.loads(self.audio_metadata["ZYNTHBOX_ACTIVELAYER"][0])
                if len(jsondata["layers"]) > 0:
                    return True;
            except:
                pass
        return False;

    sketchContainsSound = Property(bool, get_sketchContainsSound, notify=sound_data_changed)
    ### END Property sketchContainsSound

    ### BEGIN Property sketchContainsSamples
    def get_sketchContainsSamples(self):
        if self.audio_metadata is not None:
            try:
                sampleData = json.loads(self.audio_metadata["ZYNTHBOX_SAMPLES"][0])
                if len(sampleData) > 0:
                    return True
            except:
                pass
        return False

    samples_data_changed = Signal()

    sketchContainsSamples = Property(bool, get_sketchContainsSamples, notify=samples_data_changed)
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

    @Slot(None)
    def saveMetadata(self):
        if self.__song__.isLoading == False:
            self.saveMetadataTimer.start()

    def doSaveMetadata(self):
        if self.audioSource is not None:
            self.write_metadata("ZYNTHBOX_STARTPOSITION", [str(self.__start_position__)])
            self.write_metadata("ZYNTHBOX_LENGTH", [str(self.__length__)])
            self.write_metadata("ZYNTHBOX_PITCH", [str(self.__pitch__)])
            self.write_metadata("ZYNTHBOX_SPEED_RATIO", [str(self.__speed_ratio__)])
            self.write_metadata("ZYNTHBOX_GAIN", [str(self.__gain__)])
            self.write_metadata("ZYNTHBOX_PLAYBACK_STYLE", [str(self.audioSource.playbackStyle())])
            self.write_metadata("ZYNTHBOX_LOOPDELTA", [str(self.__loop_delta__)])
            self.write_metadata("ZYNTHBOX_SNAP_LENGTH_TO_BEAT", [str(self.__snap_length_to_beat__)])
            self.write_metadata("ZYNTHBOX_ADSR_ATTACK", [str(self.audioSource.adsrAttack())])
            self.write_metadata("ZYNTHBOX_ADSR_DECAY", [str(self.audioSource.adsrDecay())])
            self.write_metadata("ZYNTHBOX_ADSR_SUSTAIN", [str(self.audioSource.adsrSustain())])
            self.write_metadata("ZYNTHBOX_ADSR_RELEASE", [str(self.audioSource.adsrRelease())])
            self.write_metadata("ZYNTHBOX_GRAINERATOR_POSITION", [str(self.audioSource.grainPosition())])
            self.write_metadata("ZYNTHBOX_GRAINERATOR_SPRAY", [str(self.audioSource.grainSpray())])
            self.write_metadata("ZYNTHBOX_GRAINERATOR_SCAN", [str(self.audioSource.grainScan())])
            self.write_metadata("ZYNTHBOX_GRAINERATOR_INTERVAL", [str(self.audioSource.grainInterval())])
            self.write_metadata("ZYNTHBOX_GRAINERATOR_INTERVAL_ADDITIONAL", [str(self.audioSource.grainIntervalAdditional())])
            self.write_metadata("ZYNTHBOX_GRAINERATOR_SIZE", [str(self.audioSource.grainSize())])
            self.write_metadata("ZYNTHBOX_GRAINERATOR_SIZE_ADDITIONAL", [str(self.audioSource.grainSizeAdditional())])
            self.write_metadata("ZYNTHBOX_GRAINERATOR_PAN_MINIMUM", [str(self.audioSource.grainPanMinimum())])
            self.write_metadata("ZYNTHBOX_GRAINERATOR_PAN_MAXIMUM", [str(self.audioSource.grainPanMaximum())])
            self.write_metadata("ZYNTHBOX_GRAINERATOR_SUSTAIN", [str(self.audioSource.grainSustain())])
            self.write_metadata("ZYNTHBOX_GRAINERATOR_TILT", [str(self.audioSource.grainTilt())])
            self.write_metadata("ZYNTHBOX_GRAINERATOR_PITCH_MINIMUM1", [str(self.audioSource.grainPitchMinimum1())])
            self.write_metadata("ZYNTHBOX_GRAINERATOR_PITCH_MAXIMUM1", [str(self.audioSource.grainPitchMaximum1())])
            self.write_metadata("ZYNTHBOX_GRAINERATOR_PITCH_MINIMUM2", [str(self.audioSource.grainPitchMinimum2())])
            self.write_metadata("ZYNTHBOX_GRAINERATOR_PITCH_MAXIMUM2", [str(self.audioSource.grainPitchMaximum2())])
            self.write_metadata("ZYNTHBOX_GRAINERATOR_PITCH_PRIORITY", [str(self.audioSource.grainPitchPriority())])

    @Slot(QObject)
    def copyFrom(self, clip):
        self.clear()
        self.deserialize(clip.serialize())

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

            self.enabled_changed.emit(self.col, self.part)

    enabled_changed = Signal(int, int, arguments=["trackIndex", "partIndex"])

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
