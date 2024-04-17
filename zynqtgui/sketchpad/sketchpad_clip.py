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

from datetime import datetime
from pathlib import Path
from subprocess import check_output
from PySide2.QtCore import Property, QObject, QTimer, Qt, Signal, Slot
from zynqtgui import zynthian_gui_config


class sketchpad_clip(QObject):
    def __init__(self, row_index: int, col_index: int, part_index: int, song: QObject, parent=None, is_channel_sample=False):
        super(sketchpad_clip, self).__init__(parent)
        self.zynqtgui = zynthian_gui_config.zynqtgui

        self.is_channel_sample = is_channel_sample
        self.__row_index__ = row_index
        self.__col_index__ = col_index
        self.__part_index__ = part_index
        self.__initial_length__ = 4
        self.__length__ = self.__initial_length__
        self.__initial_start_position__ = 0.0
        self.__start_position__ = self.__initial_start_position__
        self.__loop_delta__ = 0.0
        # self.__start_position_before_sync__ = None
        self.__path__ = None
        self.__filename__ = ""
        self.__song__ = song
        self.__initial_pitch__ = 0
        self.__pitch__ = self.__initial_pitch__
        self.__initial_time__ = 1
        self.__time__ = self.__initial_time__
        self.__initial_gain__ = 0
        self.__gain__ = self.__initial_gain__
        self.__progress__ = 0.0
        self.__audio_level__ = -200
        self.__current_beat__ = -1
        self.__should_sync__ = False
        self.__playing_started__ = False
        self.audioSource = None
        self.audio_metadata = None
        self.recording_basepath = song.sketchpad_folder
        self.wav_path = Path(self.__song__.sketchpad_folder) / 'wav'
        self.__snap_length_to_beat__ = True
        self.__slices__ = 16
        self.__enabled__ = False
        self.channel = None
        self.__lane__ = part_index
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

        try:
            # Check if a dir named <somerandomname>.<channel_id> exists.
            # If exists, use that name as the bank dir name otherwise use default name `sample-bank`
            bank_name = [x.name for x in self.__base_samples_dir__.glob(f"*.{self.id + 1}")][0].split(".")[0]
        except:
            bank_name = "sample-bank"
        self.bank_path = Path(self.__song__.sketchpad_folder) / 'wav' / 'sampleset' / f'{bank_name}.{self.row + 1}'

        Zynthbox.SyncTimer.instance().bpmChanged.connect(self.update_synced_values, Qt.QueuedConnection)
        self.__song__.get_metronome_manager().current_beat_changed.connect(self.update_current_beat, Qt.QueuedConnection)

        try:
            self.channel = self.__song__.channelsModel.getChannel(self.__row_index__)
        except:
            pass

        self.__sync_in_current_scene_timer__ = QTimer()
        self.__sync_in_current_scene_timer__.setSingleShot(True)
        self.__sync_in_current_scene_timer__.setInterval(50)
        self.__sync_in_current_scene_timer__.timeout.connect(self.sync_in_current_scene)

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

        # Find the base filename excluding our suffix (sketch.wav or .clip.wav)
        categoryPrefix = "clip"
        if str(file_path).endswith(".sketch.wav"):
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

    def sync_in_current_scene(self):
        self.in_current_scene_changed.emit()

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
    def get_initial_time(self):
        return self.__initial_time__
    initialTime = Property(float, get_initial_time, constant=True)
    ### END Property initialTime

    ### Property initialGain
    def get_initial_gain(self):
        return self.__initial_gain__
    initialGain = Property(float, get_initial_gain, constant=True)
    ### END Property initialGain

    def update_current_beat(self):
        if self.audioSource is not None:
            if not self.__playing_started__:
                if self.__song__.get_metronome_manager().currentBeat == 0:
                    self.__current_beat__ = 0
                    self.__playing_started__ = True
            else:
                self.__current_beat__ = (self.__current_beat__ + 1) % self.__length__
            self.current_beat_changed.emit()

    @Slot(int)
    def setVolume(self, vol):
        if self.audioSource is not None:
            self.audioSource.setVolume(vol)

    @Signal
    def current_beat_changed(self):
        pass

    def get_current_beat(self):
        return self.__current_beat__

    currentBeat = Property(int, get_current_beat, notify=current_beat_changed)

    def update_synced_values(self):
        self.__update_synced_values_throttle.start()

    def update_synced_values_actual(self):
        if self.__should_sync__:
            new_ratio = Zynthbox.SyncTimer.instance().getBpm() / self.metadataBPM
            logging.info(f"Song BPM : {Zynthbox.SyncTimer.instance().getBpm()} - Sample BPM: {self.metadataBPM} - New Speed Ratio : {new_ratio}")
            self.set_time(new_ratio, True)

            # if self.__start_position_before_sync__ is not None:
            #     self.startPosition = new_ratio * self.__start_position__

        # Set length to recalculate loop time
        self.set_length(self.__length__, True)
        self.sec_per_beat_changed.emit()

    def serialize(self):
        return {"path": self.__path__,
                "start": self.__start_position__,
                "loopDelta": self.__loop_delta__,
                "bpm": self.metadataBPM,
                "length": self.__length__,
                "pitch": self.__pitch__,
                "time": self.__time__,
                "enabled": self.__enabled__,
                "shouldSync": self.__should_sync__,
                "snapLengthToBeat": self.__snap_length_to_beat__}

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
            if "start" in obj:
                self.__start_position__ = obj["start"]
                self.set_start_position(self.__start_position__, True)
            if "loopDelta" in obj:
                self.__loop_delta__ = obj["loopDelta"]
                self.set_loop_delta(self.__loop_delta__, True)
            if "length" in obj:
                self.__length__ = obj["length"]
                self.set_length(self.__length__, True)
            if "pitch" in obj:
                self.__pitch__ = obj["pitch"]
                self.set_pitch(self.__pitch__, True)
            if "gain" in obj:
                self.__gain__ = obj["gain"]
                self.set_gain(self.__gain__, True)
            if "time" in obj:
                self.__time__ = obj["time"]
                self.set_time(self.__time__, True)
            if "enabled" in obj:
                self.__enabled__ = obj["enabled"]
                self.set_enabled(self.__enabled__, True)
            if "shouldSync" in obj:
                self.__should_sync__ = obj["shouldSync"]
                self.set_shouldSync(self.__should_sync__, True)
            if "snapLengthToBeat" in obj:
                self.__snap_length_to_beat__ = obj["snapLengthToBeat"]
                self.set_snap_length_to_beat(self.__snap_length_to_beat__, True)
        except Exception as e:
            logging.error(f"Error during clip deserialization: {e}")
            traceback.print_exception(None, e, e.__traceback__)

    @Signal
    def length_changed(self):
        pass

    @Signal
    def row_index_changed(self):
        pass

    @Signal
    def col_index_changed(self):
        pass

    @Signal
    def path_changed(self):
        pass

    @Signal
    def start_position_changed(self):
        pass

    @Signal
    def duration_changed(self):
        pass

    @Signal
    def pitch_changed(self):
        pass

    @Signal
    def time_changed(self):
        pass

    @Signal
    def bpm_changed(self):
        pass

    @Signal
    def should_sync_changed(self):
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
    nameEditable = Property(bool, constant=True)

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


    @Signal
    def gain_changed(self):
        pass

    def get_gain(self):
        return self.__gain__

    def set_gain(self, gain: float, force_set=False):
        if self.__gain__ != gain or force_set is True:
            self.__gain__ = gain
            self.gain_changed.emit()
            if force_set is False:
                self.__song__.schedule_save()
                self.saveMetadata()

            if self.audioSource is not None:
                self.audioSource.setGain(gain)

    @Slot(None)
    def updateGain(self):
        if self.audioSource is not None:
            self.set_gain(self.audioSource.getGainDB())

    gain = Property(float, get_gain, set_gain, notify=gain_changed)


    def length(self):
        return self.__length__

    def set_length(self, length: float, force_set=False):
        if self.__length__ != length or force_set is True:
            self.__length__ = length
            self.length_changed.emit()
            if force_set is False:
                self.__song__.schedule_save()
                self.saveMetadata()

            if self.audioSource is not None:
                self.audioSource.setLength(self.__length__, Zynthbox.SyncTimer.instance().getBpm())
            self.reset_beat_count()
    length = Property(float, length, set_length, notify=length_changed)


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


    def startPosition(self):
        return self.__start_position__

    def set_start_position(self, position: float, force_set=False):
        if self.__start_position__ != position or force_set is True:
            self.__start_position__ = position
            self.start_position_changed.emit()
            if force_set is False:
                self.__song__.schedule_save()
                self.saveMetadata()

            if self.audioSource is None:
                return
            self.audioSource.setStartPosition(position)
            self.reset_beat_count()

    startPosition = Property(float, startPosition, set_start_position, notify=start_position_changed)

    def duration(self):
        if self.audioSource is None:
            return 0.0
        return self.audioSource.getDuration()

    duration = Property(float, duration, notify=duration_changed)



    def pitch(self):
        return self.__pitch__

    def set_pitch(self, pitch: int, force_set=False):
        if self.__pitch__ != math.floor(pitch) or force_set is True:
            self.__pitch__ = math.floor(pitch)
            self.pitch_changed.emit()
            if force_set is False:
                self.__song__.schedule_save()
                self.saveMetadata()

            if self.audioSource is None:
                return
            self.audioSource.setPitch(pitch)
            self.reset_beat_count()

    pitch = Property(int, pitch, set_pitch, notify=pitch_changed)


    def time(self):
        return self.__time__

    def set_time(self, time: float, force_set=False):
        if self.__time__ != time or force_set is True:
            self.__time__ = time
            self.time_changed.emit()
            if force_set is False:
                self.__song__.schedule_save()
                self.saveMetadata()

            if self.audioSource is None:
                return
            self.audioSource.setSpeedRatio(time)
            self.reset_beat_count()

    time = Property(float, time, set_time, notify=time_changed)


    def shouldSync(self):
        return self.__should_sync__

    def set_shouldSync(self, shouldSync: bool, force_set=False):
        if self.__should_sync__ != shouldSync or force_set is True:
            # if shouldSync:
            #     self.__start_position_before_sync__ = self.__start_position__

            self.__should_sync__ = shouldSync
            self.should_sync_changed.emit()
            self.update_synced_values()
            if force_set is False:
                self.__song__.schedule_save()

            if not shouldSync:
                self.set_time(1.0)
                # Set length to recalculate loop time
                self.set_length(self.__length__)

                # if self.__start_position_before_sync__ is not None:
                #     self.startPosition = self.__start_position_before_sync__
                #     self.__start_position_before_sync__ = None

    shouldSync = Property(bool, shouldSync, set_shouldSync, notify=should_sync_changed)


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
        self.audioSource = Zynthbox.ClipAudioSource(path, False, self)
        self.audioSource.isPlayingChanged.connect(self.is_playing_changed.emit)
        self.audioSource.setLaneAffinity(self.__lane__)
        if self.clipChannel is not None and self.__song__.isLoading == False:
            self.clipChannel.channelAudioType = "sample-loop"
        self.cppObjIdChanged.emit()

        self.__read_metadata__()

        playbackStyle = str(self.__get_metadata_prop__("ZYNTHBOX_PLAYBACK_STYLE", ""))
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
        self.audioSource.setLoopDelta(self.__loop_delta__)
        self.__pitch__ = int(self.__get_metadata_prop__("ZYNTHBOX_PITCH", self.__initial_pitch__))
        self.__time__ = float(self.__get_metadata_prop__("ZYNTHBOX_SPEED", self.__initial_time__))
        self.__gain__ = float(self.__get_metadata_prop__("ZYNTHBOX_GAIN", self.__initial_gain__))
        self.__progress__ = 0.0
        self.__audio_level__ = -200
        self.__snap_length_to_beat__ = (self.__get_metadata_prop__("ZYNTHBOX_SNAP_LENGTH_TO_BEAT", 'True').lower() == "true")
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

        self.reset_beat_count()

        self.audioSource.progressChanged.connect(self.progress_changed_cb, Qt.QueuedConnection)
        self.audioSource.gainAbsoluteChanged.connect(self.updateGain, Qt.QueuedConnection)
        self.audioSource.playbackStyleChanged.connect(self.saveMetadata, Qt.QueuedConnection)

        # self.startPosition = self.__start_position__
        # self.length = self.__length__
        # self.pitch - self.__pitch__
        # self.time = self.__time__
        self.set_length(self.__length__, True)
        self.set_start_position(self.__start_position__, True)
        self.set_loop_delta(self.__loop_delta__, True)
        self.set_time(self.__time__, True)
        self.set_pitch(self.__pitch__, True)
        self.set_gain(self.__gain__, True)
        self.set_snap_length_to_beat(self.__snap_length_to_beat__, True)

        # self.audioSource.set_start_position(self.__start_position__)
        self.path_changed.emit()
        self.sound_data_changed.emit()
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

        self.__path__ = None
        self.__filename__ = ""
        self.path_changed.emit()
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
            self.reset_beat_count()
            if self.audioSource is not None:
                self.__song__.partsModel.getPart(self.__col_index__).isPlaying = False

    def reset_beat_count(self):
        self.__current_beat__ = -1
        self.__playing_started__ = False

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

        if self.path is not None:
            try:
                self.audio_metadata = taglib.File(self.path).tags
                self.sound_data_changed.emit()
                self.metadata_bpm_changed.emit()
                self.metadata_audio_type_changed.emit()
                self.metadata_midi_recording_changed.emit()
                self.samples_data_changed.emit()
            except Exception as e:
                # logging.error(f"Cannot read metadata : {str(e)}")
                pass

    def __get_metadata_prop__(self, name, default):
        try:
            value = self.audio_metadata[name][0]
            # logging.debug(f"Restoring from metadata : {name}({value})")
            return value
        except:
            return default

    def metadata(self):
        return self.audio_metadata

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

    ### BEGIN Property metadataActiveLayer
    def get_metadataActiveLayer(self):
        data = ""
        if self.audio_metadata is not None:
            try:
                data = self.audio_metadata["ZYNTHBOX_ACTIVELAYER"][0]
            except:
                pass
        return data

    metadataActiveLayer = Property(str, get_metadataActiveLayer, notify=sound_data_changed)
    ### END Property metadataActiveLayer

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

    ### BEGIN Property metadataSamples
    def get_metadataSamples(self):
        if self.audio_metadata is not None:
            return self.audio_metadata["ZYNTHBOX_SAMPLES"]
        return ""
    metadataSamples = Property(str, get_metadataSamples, notify=samples_data_changed)
    ### END Property metadataSamples

    ### BEGIN Property metadataSamplePickingStyle
    def get_metadataSamplePickingStyle(self):
        if self.audio_metadata is not None:
            try:
                return int(self.audio_metadata["ZYNTHBOX_SAMPLE_PICKING_STYLE"][0])
            except Exception as e:
                pass
        return 0

    metadataSamplePickingStyle = Property(int, get_metadataSamplePickingStyle, notify=sound_data_changed)
    ### END Property metadataSamplePickingStyle

    ### BEGIN Property metadataAudioTypeSettings
    def get_metadataAudioTypeSettings(self):
        if self.audio_metadata is not None:
            try:
                return self.audio_metadata["ZYNTHBOX_AUDIOTYPESETTINGS"][0]
            except:
                pass
        return ""

    def set_metadataAudioTypeSettings(self, audioTypeSettings):
        if self.get_metadataAudioTypeSettings() != audioTypeSettings:
            self.write_metadata("ZYNTHBOX_AUDIOTYPESETTINGS", [str(audioTypeSettings)])
            self.metadataAudioTypeSettingsChanged.emit()

    metadataAudioTypeSettingsChanged = Signal()

    metadataAudioTypeSettings = Property(str, get_metadataAudioTypeSettings, set_metadataAudioTypeSettings, notify=metadataAudioTypeSettingsChanged)
    ### END Property metadataAudioTypeSettings

    ### BEGIN Property metadataRoutingStyle
    def get_metadataRoutingStyle(self):
        if self.audio_metadata is not None:
            try:
                return self.audio_metadata["ZYNTHBOX_ROUTING_STYLE"][0]
            except Exception as e:
                pass
        return ""

    def set_metadataRoutingStyle(self, routingStyle):
        if self.get_metadataRoutingStyle() != routingStyle:
            self.write_metadata("ZYNTHBOX_ROUTING_STYLE", [str(routingStyle)])
            self.metadataRoutingStyleChanged.emit()

    metadataRoutingStyleChanged = Signal()

    metadataRoutingStyle = Property(str, get_metadataRoutingStyle, set_metadataRoutingStyle, notify=metadataRoutingStyleChanged)
    ### END Property metadataRoutingStyle

    @Signal
    def sec_per_beat_changed(self):
        pass

    def get_secPerBeat(self):
        return 60.0/Zynthbox.SyncTimer.instance().getBpm()

    secPerBeat = Property(float, get_secPerBeat, notify=sec_per_beat_changed)

    @Signal
    def metadata_bpm_changed(self):
        pass

    def set_metadata_bpm(self, bpm:int):
        if (self.get_metadataBPM() != bpm):
            self.write_metadata("ZYNTHBOX_BPM", [str(bpm)])
            self.metadata_bpm_changed.emit()

    def get_metadataBPM(self):
        try:
            if self.audio_metadata is not None:
                # Sometimes bpm is stored as float like 120.0 which is causing int() to throw an exception
                # So first convert it to float and then to int to avoid the problem
                return int(float(self.audio_metadata["ZYNTHBOX_BPM"][0]))
        except Exception as e:
            logging.debug(f"Error retrieving from metadata : {str(e)}")

        return None

    metadataBPM = Property(int, get_metadataBPM, set_metadata_bpm, notify=metadata_bpm_changed)

    @Signal
    def metadata_midi_recording_changed(self):
        pass

    def get_metadata_midi_recording(self):
        try:
            if self.audio_metadata is not None:
                return str(self.audio_metadata["ZYNTHBOX_MIDI_RECORDING"][0])
        except Exception as e:
            logging.debug(f"Error retrieving from metadata : {str(e)}")

        return None

    @Slot(str)
    def set_metadata_midi_recording(self, midi_recording_base64):
        self.write_metadata("ZYNTHBOX_MIDI_RECORDING", [str(midi_recording_base64)])
        self.metadata_midi_recording_changed.emit()

    metadataMidiRecording = Property(str, get_metadata_midi_recording, set_metadata_midi_recording, notify=metadata_midi_recording_changed)

    def get_metadata_pattern_json(self):
        try:
            if self.audio_metadata is not None:
                return str(self.audio_metadata["ZYNTHBOX_PATTERN_JSON"][0])
        except Exception as e:
            logging.debug(f"Error retrieving from metadata : {str(e)}")
        return None

    @Slot(str)
    def set_metadata_pattern_json(self, patter_as_json):
        self.write_metadata("ZYNTHBOX_PATTERN_JSON", [str(patter_as_json)])
        self.metadata_pattern_json_changed.emit()

    @Signal
    def metadata_pattern_json_changed(self):
        pass

    metadataPatternJson = Property(str, get_metadata_pattern_json, set_metadata_pattern_json, notify=metadata_pattern_json_changed)
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
            self.write_metadata("ZYNTHBOX_SPEED", [str(self.__time__)])
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

    ### Property metadataAudioType
    def get_metadata_audio_type(self):
        try:
            if self.audio_metadata is not None:
                return self.audio_metadata["ZYNTHBOX_AUDIO_TYPE"][0]
        except Exception as e:
            logging.debug(f"Error retrieving from metadata : {str(e)}")
        return None
    metadata_audio_type_changed = Signal()
    metadataAudioType = Property(str, get_metadata_audio_type, notify=metadata_audio_type_changed)
    ### END Property metadataAudioType

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

    ### Property snapLengthToBeat
    def get_snap_length_to_beat(self):
        return self.__snap_length_to_beat__

    def set_snap_length_to_beat(self, val, force_set=False):
        if self.__snap_length_to_beat__ != val or force_set is True:
            self.__snap_length_to_beat__ = val
            self.snap_length_to_beat_changed.emit()
            if force_set is False:
                self.__song__.schedule_save()
                self.saveMetadata()

    snap_length_to_beat_changed = Signal()

    snapLengthToBeat = Property(bool, get_snap_length_to_beat, set_snap_length_to_beat, notify=snap_length_to_beat_changed)
    ### END Property snapLengthToBeat

    ### Property loopDelta
    def get_loop_delta(self):
        return self.__loop_delta__

    def set_loop_delta(self, val, force_set=False):
        if self.__loop_delta__ != val or force_set is True:
            self.__loop_delta__ = val
            if self.audioSource is not None:
                self.audioSource.setLoopDelta(val)
            self.loop_delta_changed.emit()
            if force_set is False:
                self.__song__.schedule_save()
                self.saveMetadata()

    loop_delta_changed = Signal()

    loopDelta = Property(float, get_loop_delta, set_loop_delta, notify=loop_delta_changed)
    ### END Property loopDelta

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

    className = Property(str, className, constant=True)
    recordingDir = Property(str, recordingDir, constant=True)
