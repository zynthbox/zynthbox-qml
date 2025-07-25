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

        self.__originalPath = ""
        # Sound metadata
        self.__audioType = None
        self.__audioTypeSettings = None
        self.__midiRecording = None
        self.__patternJson = None
        self.__routingStyle = None
        self.__samplePickingStyle = None
        self.__samples = None
        self.__soundSnapshot = None

    def get_originalPath(self): return self.__originalPath
    def get_audioType(self): return self.__audioType
    def get_audioTypeSettings(self): return self.__audioTypeSettings
    def get_midiRecording(self): return self.__midiRecording
    def get_patternJson(self): return self.__patternJson
    def get_routingStyle(self): return self.__routingStyle
    def get_samplePickingStyle(self): return self.__samplePickingStyle
    def get_samples(self): return self.__samples
    def get_soundSnapshot(self): return self.__soundSnapshot

    def set_originalPath(self, value):
        if self.__originalPath != value:
            self.__originalPath = value
            self.originalPathChanged.emit()
            self.scheduleSave()

    def set_audioType(self, value, write=True, force=False):
        if value != self.__audioType or force:
            self.__audioType = value
            self.audioTypeChanged.emit()
            if write:
                self.scheduleSave()
    def set_audioTypeSettings(self, value, write=True, force=False):
        if value != self.__audioTypeSettings or force:
            self.__audioTypeSettings = value
            self.audioTypeSettingsChanged.emit()
            if write:
                self.scheduleSave()
    def set_midiRecording(self, value, write=True, force=False):
        if value != self.__midiRecording or force:
            self.__midiRecording = value
            self.midiRecordingChanged.emit()
            if write:
                self.scheduleSave()
    def set_patternJson(self, value, write=True, force=False):
        if value != self.__patternJson or force:
            self.__patternJson = value
            self.patternJsonChanged.emit()
            if write:
                self.scheduleSave()
    def set_routingStyle(self, value, write=True, force=False):
        if value != self.__routingStyle or force:
            self.__routingStyle = value
            self.routingStyleChanged.emit()
            if write:
                self.scheduleSave()
    def set_samplePickingStyle(self, value, write=True, force=False):
        if value != self.__samplePickingStyle or force:
            self.__samplePickingStyle = value
            self.samplePickingStyleChanged.emit()
            if write:
                self.scheduleSave()
    def set_samples(self, value, write=True, force=False):
        if value != self.__samples or force:
            self.__samples = value
            self.samplesChanged.emit()
            if write:
                self.scheduleSave()
    def set_soundSnapshot(self, value, write=True, force=False):
        if value != self.__soundSnapshot or force:
            self.__soundSnapshot = value
            self.soundSnapshotChanged.emit()
            if write:
                self.scheduleSave()

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

    originalPathChanged = Signal()
    audioTypeChanged = Signal()
    audioTypeSettingsChanged = Signal()
    midiRecordingChanged = Signal()
    patternJsonChanged = Signal()
    routingStyleChanged = Signal()
    samplePickingStyleChanged = Signal()
    samplesChanged = Signal()
    soundSnapshotChanged = Signal()

    originalPath = Property(str, get_originalPath, set_originalPath, notify=originalPathChanged)
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
                equaliserCompressorObject.equaliserEnabledChanged.connect(self.scheduleSave)
                for filterObject in equaliserCompressorObject.equaliserSettings():
                    filterObject.filterTypeChanged.connect(self.scheduleSave)
                    filterObject.frequencyChanged.connect(self.scheduleSave)
                    filterObject.qualityChanged.connect(self.scheduleSave)
                    filterObject.soloedChanged.connect(self.scheduleSave)
                    filterObject.gainChanged.connect(self.scheduleSave)
                    filterObject.activeChanged.connect(self.scheduleSave)
                equaliserCompressorObject.compressorEnabledChanged.connect(self.scheduleSave)
                equaliserCompressorObject.compressorSidechannelLeftChanged.connect(self.scheduleSave)
                equaliserCompressorObject.compressorSidechannelRightChanged.connect(self.scheduleSave)
                equaliserCompressorObject.compressorSettings().thresholdChanged.connect(self.scheduleSave)
                equaliserCompressorObject.compressorSettings().makeUpGainChanged.connect(self.scheduleSave)
                equaliserCompressorObject.compressorSettings().kneeWidthChanged.connect(self.scheduleSave)
                equaliserCompressorObject.compressorSettings().releaseChanged.connect(self.scheduleSave)
                equaliserCompressorObject.compressorSettings().attackChanged.connect(self.scheduleSave)
                equaliserCompressorObject.compressorSettings().ratioChanged.connect(self.scheduleSave)
            connectEqualiserAndCompressorForSaving(self.clip.audioSource)
            self.clip.audioSource.bpmChanged.connect(self.scheduleSave)
            self.clip.audioSource.autoSynchroniseSpeedRatioChanged.connect(self.scheduleSave)
            self.clip.audioSource.speedRatioChanged.connect(self.scheduleSave)
            self.clip.audioSource.sliceCountChanged.connect(self.scheduleSave)
            self.clip.audioSource.slicesContiguousChanged.connect(self.scheduleSave)
            self.clip.audioSource.sliceDataChanged.connect(self.scheduleSave)

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

    def read(self, load_autosave=True):
        self.__isReading = True
        if not self.clip.isEmpty:
            audioMetadata = None
            try:
                file = taglib.File(self.clip.path)
                if load_autosave and "AUTOSAVE" in file.tags:
                    logging.debug(f"Clip metadata reading {self.clip} : autosave")
                    self.__audioMetadata = json.loads(file.tags["AUTOSAVE"][0])
                else:
                    logging.debug(f"Clip metadata reading {self.clip} : NOT autosave")
                audioMetadata = file.tags
                file.close()
            except Exception as e:
                logging.error(f"Error reading metadata from sketch {self.clip.path} : {str(e)}")

            self.deserialize(audioMetadata)
        self.__isReading = False

    @Slot()
    def writeMetadataWithoutSoundData(self):
        if self.clip.audioSource is None:
            logging.error("Attempted to write metadata for a clip, but we do not have a clip for which to write that data")
        else:
            self.write(writeSoundMetadata=False, path=self.clip.path)

    @Slot()
    def writeMetadataWithSoundData(self):
        if self.clip.audioSource is None:
            logging.error("Attempted to write metadata with sound data for a clip, but we do not have a clip for which to write that data")
        else:
            self.write(writeSoundMetadata=True, path=self.clip.path)

    def write(self, writeSoundMetadata=False, path=None):
        if path is None:
            logging.error("Attempted to write metadata for a clip, without being given a path - that is not how we do things any longer!")
        else:
            if self.__isReading == False and self.clip.__song__.isLoading == False and self.clip.__song__.isSaving == False:
                if not self.clip.isEmpty:
                    tags = self.serialize()
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
                        self.set_soundSnapshot(self.clip.channel.getChannelSoundSnapshot(), write=False, force=True)

                        tags["ZYNTHBOX_TRACK_TYPE"] = [str(self.__audioType)]
                        tags["ZYNTHBOX_TRACK_AUDIOTYPESETTINGS"] = [str(self.__audioTypeSettings)]
                        tags["ZYNTHBOX_MIDI_RECORDING"] = [str(self.__midiRecording)]
                        tags["ZYNTHBOX_PATTERN_JSON"] = [str(self.__patternJson)]
                        tags["ZYNTHBOX_ROUTING_STYLE"] = [str(self.__routingStyle)]
                        tags["ZYNTHBOX_SAMPLE_PICKING_STYLE"] = [str(self.__samplePickingStyle)]
                        tags["ZYNTHBOX_SAMPLES"] = [str(self.__samples)]
                        tags["ZYNTHBOX_SOUND_SNAPSHOT"] = [str(self.__soundSnapshot)]

                    try:
                        file = taglib.File(path)
                        for key, value in tags.items():
                            file.tags[key] = value
                        file.save()
                    except Exception as e:
                        logging.exception(f"Error writing metadata : {str(e)}")
                        logging.info("Trying to create a new file without metadata")

                        try:
                            with tempfile.TemporaryDirectory() as tmp:
                                logging.info("Creating new temp file without metadata")
                                logging.debug(f"ffmpeg -i {path} -codec copy {Path(tmp) / 'output.wav'}")
                                check_output(f"ffmpeg -i {path} -codec copy {Path(tmp) / 'output.wav'}", shell=True)

                                logging.info("Replacing old file")
                                logging.debug(f"mv {Path(tmp) / 'output.wav'} {path}")
                                check_output(f"mv {Path(tmp) / 'output.wav'} {path}", shell=True)

                                file = taglib.File(path)
                                for key, value in tags.items():
                                    file.tags[key] = value
                                file.save()
                        except Exception as e:
                            logging.error(f"Error creating new file and writing metadata : {str(e)}")
                self.__isWriting = False

    def serialize(self):
        tags = {}
        if self.clip.audioSource:
            if len(self.__originalPath) > 0:
                tags["ZYNTHBOX_ORIGINAL_PATH"] = [str(self.__originalPath)]
            tags["ZYNTHBOX_BPM"] = [str(self.clip.audioSource.bpm())]
            tags["ZYNTHBOX_SPEED_RATIO"] = [str(self.clip.audioSource.speedRatio())]
            tags["ZYNTHBOX_SYNC_SPEED_TO_BPM"] = [str(self.clip.audioSource.autoSynchroniseSpeedRatio())]
            tags["ZYNTHBOX_EQUALISER_SETTINGS"] = [str(json.dumps(serializeEqualiserAndCompressorSettings(self.clip.audioSource)))]
            tags["ZYNTHBOX_SLICE_SETTINGS"] = [self.clip.audioSource.slicesToString()]
            # Root slice settings
            tags["ZYNTHBOX_ROOT_NOTE"] = [str(self.clip.audioSource.rootSlice().rootNote())]
            tags["ZYNTHBOX_KEYZONE_START"] = [str(self.clip.audioSource.rootSlice().keyZoneStart())]
            tags["ZYNTHBOX_KEYZONE_END"] = [str(self.clip.audioSource.rootSlice().keyZoneEnd())]
            tags["ZYNTHBOX_VELOCITY_MINIMUM"] = [str(self.clip.audioSource.rootSlice().velocityMinimum())]
            tags["ZYNTHBOX_VELOCITY_MAXIMUM"] = [str(self.clip.audioSource.rootSlice().velocityMaximum())]
            tags["ZYNTHBOX_PAN"] = [str(self.clip.audioSource.rootSlice().pan())]
            tags["ZYNTHBOX_GAIN"] = [str(self.clip.audioSource.rootSlice().gainHandler().gainDb())]
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
        return tags

    def deserialize(self, obj):
        self.__audioMetadata = obj
        # TODO Probably have some fault safety here, in case there's bunk metadata?
        if self.clip.audioSource is not None:
            self.set_originalPath(str(self.getMetadataProperty("ZYNTHBOX_ORIGINAL_PATH", "")))
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
            self.clip.audioSource.stringToSlices(str(self.getMetadataProperty("ZYNTHBOX_SLICE_SETTINGS", "")))
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
            self.clip.audioSource.rootSlice().gainHandler().setGainDb(float(self.getMetadataProperty("ZYNTHBOX_GAIN", self.clip.initialGain)))
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

    def scheduleSave(self):
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
        self.__title__ = ""
        self.__path__ = None
        self.__filename__ = ""
        self.__song__ = song
        self.__initial_length__ = 4
        self.__initial_start_position__ = 0.0
        self.__initial_pitch__ = 0
        self.__initial_speed_ratio = 1
        self.__speed_ratio__ = self.__initial_speed_ratio
        self.__initial_gain__ = 0 # This is the default adjustment in dB (so, no adjustment)
        self.__progress__ = 0.0
        self.audioSource = None
        self.recording_basepath = song.sketchpad_folder
        self.wav_path = Path(self.__song__.sketchpad_folder) / 'wav'
        self.__slices__ = 16
        self.__enabled__ = False
        self.channel = None
        # Samples go on lanes 0 through 4, and Sketches go on lanes 5 through 9
        self.__lane__ = id if is_channel_sample else id + 5
        self.__metadata = sketchpad_clip_metadata(self)

        # Just in case, fix up the lane so it's something sensible. We have ten lanes (one for each slot of sample and sketch), so...
        if self.__lane__ < 0 or self.__lane__ > 9:
            self.__lane__ = 0

        self.__autoStopTimer__ = QTimer()
        self.__autoStopTimer__.setSingleShot(True)
        self.__autoStopTimer__.timeout.connect(self.stop_audio)

        # Disable custom named bank temporarily. Find out if we need this or not
        # try:
        #     # Check if a dir named <somerandomname>.<channel_id> exists.
        #     # If exists, use that name as the bank dir name otherwise use default name `sample-bank`
        #     bank_name = [x.name for x in self.__base_samples_dir__.glob(f"*.{self.id + 1}")][0].split(".")[0]
        # except:
        #     bank_name = "sample-bank"
        self.bank_path = Path(self.__song__.sketchpad_folder) / 'wav' / 'sampleset' / f'sample-bank.{self.row + 1}'

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
    # Returns : An unique filename as string in the format f"{file_basename}-{counter}{.category}.wav" (where category is either "" or ".sketch")
    @staticmethod
    def generate_unique_filename(file, copy_dir):
        file_path = Path(file)
        copy_dir_path = Path(copy_dir)
        counter = 1

        # Find the base filename excluding our suffix (wav)
        category = ""
        file_basename = ""
        if file_path.name.lower().endswith(".sketch.wav"):
            category = ".sketch"
            file_basename = file_path.name.split(".sketch.wav")[0]
        else:
            file_basename = file_path.name.split(".wav")[0]
        # Remove the `counter` part from the string if exists
        file_basename = re.sub('-\d*$', '', file_basename)

        if not (copy_dir_path / f"{file_basename}{category}.wav").exists():
            return f"{file_basename}{category}.wav"
        else:
            while Path(copy_dir_path / f"{file_basename}-{counter}{category}.wav").exists():
                counter += 1

            return f"{file_basename}-{counter}{category}.wav"

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
            "enabled": self.__enabled__,
            "metadata": self.__metadata.serialize()
        }

    def deserialize(self, obj):
        logging.debug(f"clip_deserialize")
        try:
            if "path" in obj:
                if obj["path"] is None:
                    self.__path__ = None
                else:
                    if self.is_channel_sample:
                        self.set_path(str(self.bank_path / obj["path"]), should_copy=False, read_metadata=False)
                    else:
                        self.set_path(str(self.wav_path / obj["path"]), should_copy=False, read_metadata=False)
            if "enabled" in obj:
                self.__enabled__ = obj["enabled"]
                self.set_enabled(self.__enabled__, True)
            # NOTE This must happen after the path has been set (to avoid problems with the metadata fetching fallback)
            if "metadata" in obj:
                self.__metadata.deserialize(obj["metadata"])
            else:
                self.__metadata.clear()
                # If the metadata doesn't exist in the object passed to us, read it out of the file itself, if that exists
                if self.audioSource is not None:
                    self.__metadata.read()
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


    # BEGIN Property title
    # The user-defined title for this clip (or the filename if there isn't one set)
    def get_title(self):
        if self.__title__ == "":
            # Return the filename, but without .sketch.wav, .clip.wav, or .wav
            if self.__filename__.endswith(".sketch.wav"):
                return self.__filename__[:-11]
            elif self.__filename__.endswith(".clip.wav"):
                return self.__filename__[:-9]
            elif self.__filename__.endswith(".wav"):
                return self.__filename__[:-4]
            else:
                return self.__filename__
        else:
            return self.__title__

    def set_title(self, title):
        if self.__title__ != title:
            self.__title__ = title
            self.titleChanged.emit()

    titleChanged = Signal()

    title = Property(str, get_title, set_title, notify=titleChanged)
    # END Property title

    def get_clip_name(self):
        return chr(self.__id__+65)
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

    # Arg path: the original path of the wave file
    # This is essentially equivalent to calling set_path with should_copy and
    # read_metadata both set to True, but will also set the path being imported
    # on the originalPath metadata field
    @Slot(str)
    def importFromFile(self, path):
        self.set_path(path, should_copy=True, read_metadata=True)
        self.__metadata.set_originalPath(path)
        # TODO Handling duplicates: We may very well want to eventually hold only one copy of a wave asset on disk
        # and then reference-count its users, so that we can remove it from the sketchpad when all users have gone.
        # This, however, will need tracking globally, otherwise we end up unable to track when it's being used by
        # other versions of the same sketchpad, and we don't want to remove it from disk until all users have gone.

    # Arg path: Where you want to store a copy of the slot data, with the metadata stored into the file
    @Slot(str, result=bool)
    def exportToFile(self, path):
        result = False
        if len(self.__path__) > 0:
            if self.copyTo(path):
                # We don't write sound metadata here, because if it is there, we want it to remain unaltered, rather
                # than updating it with whatever we have in the track this is attached to, and if it is not there, we
                # don't want to add it in. And this function will leave it alone if it's already there.
                self.metadata.write(writeSoundMetadata=False, path=path)
                result = True
            else:
                logging.error(f"Failed to create a copy of the clip {self.__path__} to {path}")
        else:
            logging.error(f"Failed to export to file, as we do not in fact have a file to export (the path is empty)")
        return result

    # Arg path : Set path of the wav to clip
    # Arg should_copy : Controls where the selected clip should be copied under a unique name when setting.
    #                   should_copy should be set to False when restoring to avoid copying the same clip under
    #                   a different name. Otherwise when path is set from UI, it makes sure to always create a new file
    #                   when first selecting a wav for a clip.
    #                   If we copy, we also store the original path into the metadata for the slot
    # Arg read_metadata : Whether or not to read the metadata from the original file
    @Slot(str,bool,bool)
    def set_path(self, path, should_copy=True, read_metadata=False):
        logging.debug(f"Load {path}, should copy: {should_copy}, read metadata: {read_metadata}")
        if path is not None:
            new_filename = ""
            selected_path = Path(path)

            if self.is_channel_sample:
                if should_copy:
                    new_filename = self.generate_unique_filename(selected_path, self.bank_path)
                    logging.error(f"Copying sample({path}) into bank folder ({self.bank_path / new_filename})")
                    self.bank_path.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(selected_path, self.bank_path / new_filename)
            else:
                if should_copy:
                    new_filename = self.generate_unique_filename(selected_path, self.wav_path)
                    logging.error(f"Copying clip({path}) into sketchpad folder ({self.wav_path / new_filename})")
                    shutil.copy2(selected_path, self.wav_path / new_filename)

            if new_filename == "":
                self.__path__ = str(selected_path.name)
            else:
                self.__path__ = str(new_filename)
            self.__filename__ = self.__path__.split("/")[-1]
            self.stop()
        else:
            self.__path__ = None
            self.metadata.clear()

        if self.audioSource is not None:
            # Explicitly unhook, to avoid update potential clashes when we load stuff momentarily
            self.__metadata.unhook()
            try: self.audioSource.disconnect(self)
            except: pass
            self.audioSource.deleteLater()
            self.audioSource = None

        cleanedUpFilename = self.__filename__.replace("&", "&amp;")
        self.zynqtgui.currentTaskMessage = f"Loading Sketchpad : Loading Sample<br/>{cleanedUpFilename}"
        if self.__path__ is not None:
            sketchpadTrack = -1 if self.clipChannel is None else self.clipChannel.id
            registerForPolyphonicPlayback = True if self.is_channel_sample else False
            self.audioSource = Zynthbox.ClipAudioSource(self.path, sketchpadTrack, self.id, registerForPolyphonicPlayback, False, self)
            self.audioSource.rootSlice().lengthChanged.connect(self.sec_per_beat_changed.emit)
            self.audioSource.isPlayingChanged.connect(self.is_playing_changed.emit)
            self.audioSource.progressChanged.connect(self.progress_changed_cb, Qt.QueuedConnection)
            self.audioSource.setLaneAffinity(self.__lane__)

        # read() will read all the available metadata and populate default values if not available
        if read_metadata:
            self.__metadata.read()
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
    def clear(self):
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
        elif self.zynqtgui.sketchpad.song is not None and self.clipChannel is not None:
            # Clear patterns if not a sample
            Zynthbox.PlayGridManager.instance().getSequenceModel(self.zynqtgui.sketchpad.song.scenesModel.selectedSequenceName).getByClipId(self.clipChannel.id, self.id).workingModel().clear()

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
        if not self.isChannelSample:
            # Copy patterns if not a sample
            sequenceModel = Zynthbox.PlayGridManager.instance().getSequenceModel(self.zynqtgui.sketchpad.song.scenesModel.selectedSequenceName)
            sourcePattern = sequenceModel.getByClipId(clip.clipChannel.id, clip.id)
            destinationPattern = sequenceModel.getByClipId(self.clipChannel.id, self.id)
            destinationPattern.cloneOther(sourcePattern)
        self.set_path(clip.path, True, True)
        # Using the serialisation logic here which, while simply copying the properties directly would be faster, this is consistent
        self.__metadata.deserialize(clip.metadata.serialize())
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
