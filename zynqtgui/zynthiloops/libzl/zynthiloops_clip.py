#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthiloops Clip: An object to store clip information for a track
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

from datetime import datetime
from PySide2.QtCore import Property, QObject, Signal, Slot
import taglib
import json

from .libzl import ClipAudioSource

import logging

class zynthiloops_clip(QObject):
    def __init__(self, row_index: int, col_index: int, song: QObject, parent=None):
        super(zynthiloops_clip, self).__init__(parent)
        self.__length__ = 1
        self.__row_index__ = row_index
        self.__col_index__ = col_index
        self.__is_playing__ = False
        self.__start_position__ = 0.0
        self.__path__ = None
        self.__song__ = song
        self.__pitch__ = 0
        self.__time__ = 1
        self.__bpm__ = 0
        self.__gain__ = 0
        self.__progress__ = 0.0
        self.__audio_level__ = 0
        self.__current_beat__ = -1
        self.__should_sync__ = False
        self.__playing_started__ = False
        self.__is_recording__ = False
        self.audioSource: ClipAudioSource = None
        self.audio_metadata = None
        self.recording_basepath = song.sketch_folder

        self.__song__.bpm_changed.connect(lambda: self.song_bpm_changed())

        self.track = self.__song__.tracksModel.getTrack(self.__row_index__)

        if self.track is not None:
            self.track.volume_changed.connect(lambda: self.track_volume_changed())

    def update_current_beat(self):
        if not self.__playing_started__:
            if self.__song__.get_metronome_manager().currentBeat == 0:
                self.__current_beat__ = 0
                self.__playing_started__ = True
        else:
            self.__current_beat__ = (self.__current_beat__ + 1) % self.__length__
        self.current_beat_changed.emit()

    def set_row_index(self, new_index):
        self.__row_index__ = new_index
        self.track = self.__song__.tracksModel.getTrack(self.__row_index__)
        self.row_index_changed.emit()

    def track_volume_changed(self):
        self.track.volume = self.__song__.tracksModel.getTrack(self.__row_index__).volume
        logging.error(f"Track volume changed : {self.track.volume}")

        if self.audioSource is not None:
            self.audioSource.set_volume(self.track.volume/100)

    @Signal
    def current_beat_changed(self):
        pass

    def get_current_beat(self):
        return self.__current_beat__

    currentBeat = Property(int, get_current_beat, notify=current_beat_changed)

    def song_bpm_changed(self):
        self.update_synced_values()

    def update_synced_values(self):
        if self.__should_sync__:
            logging.error(f"Song BPM : {self.__song__.bpm}")
            new_ratio = self.__song__.bpm / self.__bpm__
            logging.error(f"Song New Ratio : {new_ratio}")
            self.set_time(new_ratio, True)

        # Set length to recalculate loop time
        self.set_length(self.__length__, True)
        self.sec_per_beat_changed.emit()

    def serialize(self):
        return {"path": self.__path__,
                "start": self.__start_position__,
                "length": self.__length__,
                "pitch": self.__pitch__,
                "time": self.__time__,
                "bpm": self.__bpm__,
                "shouldSync": self.__should_sync__}

    def deserialize(self, obj):
        if "path" in obj:
            if obj["path"] is None:
                self.__path__ = None
            else:
                self.path = obj["path"]
        if "start" in obj:
            self.__start_position__ = obj["start"]
            self.set_start_position(self.__start_position__, True)
        if "length" in obj:
            self.__length__ = obj["length"]
            self.set_length(self.__length__, True)
        if "pitch" in obj:
            self.__pitch__ = obj["pitch"]
            self.set_pitch(self.__pitch__, True)
        if "time" in obj:
            self.__time__ = obj["time"]
            self.set_time(self.__time__, True)
        if "bpm" in obj:
            self.__bpm__ = obj["bpm"]
            self.set_bpm(self.bpm, True)
        if "shouldSync" in obj:
            self.__should_sync__ = obj["shouldSync"]
            self.set_shouldSync(self.__should_sync__, True)

        self.track = self.__song__.tracksModel.getTrack(self.__row_index__)
        self.track.volume_changed.connect(lambda: self.track_volume_changed())

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

    @Signal
    def __is_playing_changed__(self):
        pass

    @Signal
    def __is_recording_changed__(self):
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

    def isPlaying(self):
        return self.__is_playing__
    isPlaying = Property(bool, isPlaying, notify=__is_playing_changed__)


    @Signal
    def progressChanged(self):
        pass

    def get_progress(self):
        if self.audioSource is None:
            return 0.0
        return self.__progress__

    progress = Property(float, get_progress, notify=progressChanged)


    def get_isRecording(self):
        return self.__is_recording__

    def set_isRecording(self, is_recording):
        self.__is_recording__ = is_recording
        self.__is_recording_changed__.emit()

    isRecording = Property(bool, get_isRecording, set_isRecording, notify=__is_recording_changed__)


    @Signal
    def gain_changed(self):
        pass

    def get_gain(self):
        return self.__gain__

    def set_gain(self, gain: float, force_set=False):
        if self.__gain__ != gain or force_set is True:
            self.__gain__ = gain
            self.gain_changed.emit()

            if self.audioSource is not None:
                self.audioSource.set_gain(gain)

    gain = Property(float, get_gain, set_gain, notify=gain_changed)


    def length(self):
        return self.__length__

    def set_length(self, length: int, force_set=False):
        if self.__length__ != math.floor(length) or force_set is True:
            self.__length__ = math.floor(length)
            self.length_changed.emit()
            # self.__song__.schedule_save()

            if self.audioSource is not None:
                self.audioSource.set_length(min(self.duration - self.__start_position__, (60.0 / self.__song__.bpm) * self.__length__))
            self.reset_beat_count()
    length = Property(int, length, set_length, notify=length_changed)


    def row(self):
        return self.__row_index__

    def set_row_index(self, index):
        self.__row_index__ = index
        self.row_index_changed.emit()
    
    row = Property(int, row, set_row_index, notify=row_index_changed)


    def col(self):
        return self.__col_index__

    def set_col_index(self, index):
        self.__col_index__ = index
        self.col_index_changed.emit()

    col = Property(int, col, set_col_index, notify=col_index_changed)


    def name(self):
        return f"{self.__song__.tracksModel.getTrack(self.__row_index__).name}-{chr(self.__col_index__+65)}"
    name = Property(str, name, constant=True)

    def startPosition(self):
        return self.__start_position__

    def set_start_position(self, position: float, force_set=False):
        if self.__start_position__ != position or force_set is True:
            self.__start_position__ = position
            self.start_position_changed.emit()
            # self.__song__.schedule_save()
            if self.audioSource is None:
                return
            self.audioSource.set_start_position(position)
            self.reset_beat_count()

    startPosition = Property(float, startPosition, set_start_position, notify=start_position_changed)

    def duration(self):
        if self.audioSource is None:
            return 0.0
        return self.audioSource.get_duration()

    duration = Property(float, duration, notify=duration_changed)



    def pitch(self):
        return self.__pitch__

    def set_pitch(self, pitch: int, force_set=False):
        if self.__pitch__ != math.floor(pitch) or force_set is True:
            self.__pitch__ = math.floor(pitch)
            self.pitch_changed.emit()
            # self.__song__.schedule_save()
            if self.audioSource is None:
                return
            self.audioSource.set_pitch(pitch)
            self.reset_beat_count()

    pitch = Property(int, pitch, set_pitch, notify=pitch_changed)


    def time(self):
        return self.__time__

    def set_time(self, time: float, force_set=False):
        if self.__time__ != time or force_set is True:
            self.__time__ = time
            self.time_changed.emit()
            # self.__song__.schedule_save()
            if self.audioSource is None:
                return
            self.audioSource.set_speed_ratio(time)
            self.reset_beat_count()

    time = Property(float, time, set_time, notify=time_changed)


    def bpm(self):
        return self.__bpm__

    def set_bpm(self, bpm: float, force_set=False):
        if self.__bpm__ != bpm or force_set is True:
            self.__bpm__ = bpm
            self.bpm_changed.emit()
            # self.__song__.schedule_save()
            self.reset_beat_count()

    bpm = Property(float, bpm, set_bpm, notify=bpm_changed)


    def shouldSync(self):
        return self.__should_sync__

    def set_shouldSync(self, shouldSync: bool, force_set=False):
        if self.__should_sync__ != shouldSync or force_set is True:
            self.__should_sync__ = shouldSync
            self.should_sync_changed.emit()
            self.update_synced_values()
            # self.__song__.schedule_save()

            if not shouldSync:
                self.set_time(1.0)
                # Set length to recalculate loop time
                self.set_length(self.__length__)

    shouldSync = Property(bool, shouldSync, set_shouldSync, notify=should_sync_changed)


    def path(self):
        return self.__path__

    def set_path(self, path):
        self.__path__ = path
        self.stop()

        if self.audioSource is not None:
            self.audioSource.destroy()

        self.audioSource = ClipAudioSource(self, path.encode('utf-8'))
        print(path)

        self.__length__ = 1
        self.__is_playing__ = False
        self.__is_recording__ = False
        self.__start_position__ = 0.0
        self.__pitch__ = 0
        self.__time__ = 1
        self.__bpm__ = 0
        self.__progress__ = 0.0
        self.__audio_level__ = 0
        self.__read_metadata__()
        self.reset_beat_count()

        try:
            self.audioSource.audioLevelChanged.disconnect()
            self.audioSource.progressChanged.disconnect()
        except Exception as e:
            logging.error(f"Not connected : {str(e)}")

        self.audioSource.audioLevelChanged.connect(lambda leveldB: self.audio_level_changed_cb(leveldB))
        self.audioSource.progressChanged.connect(lambda progress: self.progress_changed_cb(progress))

        try:
            logging.error(f"Setting bpm from metadata : {self.audio_metadata}")
            self.set_bpm(int(self.audio_metadata["ZYNTHBOX_BPM"][0]), True)
        except Exception as e:
            logging.error(f"Error setting bpm from metadata : {str(e)}")

        # self.startPosition = self.__start_position__
        # self.length = self.__length__
        # self.pitch - self.__pitch__
        # self.time = self.__time__
        self.set_length(self.__length__, True)
        self.set_start_position(self.__start_position__, True)
        self.set_time(self.__time__, True)
        self.set_pitch(self.__pitch__, True)

        # self.audioSource.set_start_position(self.__start_position__)
        self.path_changed.emit()
        self.sound_data_changed.emit()
        self.duration_changed.emit()
        # self.__song__.schedule_save()
    path = Property(str, path, set_path, notify=path_changed)

    def audio_level_changed_cb(self, leveldB):
        self.__audio_level__ = leveldB
        self.audioLevelChanged.emit()
        self.track.audioLevel = leveldB

    def progress_changed_cb(self, progress):
        self.__progress__ = progress
        self.progressChanged.emit()

    @Signal
    def audioLevelChanged(self):
        pass

    def get_audioLevel(self):
        return self.__audio_level__

    audioLevel = Property(float, get_audioLevel, notify=audioLevelChanged)

    @Slot(None)
    def clear(self, loop=True):
        self.stop()

        if self.audioSource is not None:
            self.audioSource.destroy()
            self.audioSource = None

        self.__path__ = None
        self.path_changed.emit()
        # self.__song__.schedule_save()

    @Slot(None)
    def play(self):
        if not self.__is_playing__:
            logging.error(f"Playing Clip {self}")

            track = self.__song__.tracksModel.getTrack(self.__row_index__)
            clipsModel = track.clipsModel

            for clip_index in range(0, clipsModel.count):
                clip: zynthiloops_clip = clipsModel.getClip(clip_index)
                logging.error(f"Track({track}), Clip({clip}: isPlaying({clip.__is_playing__}))")

                if clip.__is_playing__:
                    clip.stop()

            if self.audioSource is None:
                return

            self.__song__.get_metronome_manager().current_beat_changed.connect(self.update_current_beat)

            self.__song__.get_metronome_manager().start_metronome_request()
            self.__is_playing__ = True
            self.__is_playing_changed__.emit()
            self.audioSource.queueClipToStart()

    @Slot(None)
    def stop(self):
        if self.__is_playing__:
            logging.error(f"Stopping Clip {self}")

            try:
                self.__song__.get_metronome_manager().current_beat_changed.disconnect(self.update_current_beat)
            except:
                logging.error(f"Error disconnecting from current_beat_changed signal. Not yet connected maybe?")

            self.reset_beat_count()

            if self.audioSource is None:
                return
            self.__song__.get_metronome_manager().stop_metronome_request()
            self.__is_playing__ = False
            self.__is_playing_changed__.emit()

            # self.audioSource.stop()
            self.audioSource.queueClipToStop()

            self.__song__.partsModel.getPart(self.__col_index__).isPlaying = False

    def reset_beat_count(self):
        self.__current_beat__ = -1
        self.__playing_started__ = False

    def destroy(self):
        if self.audioSource is not None:
            self.audioSource.destroy()

    @Slot(None)
    def queueRecording(self):
        self.__song__.get_metronome_manager().queue_clip_record(self)

    @Slot(None)
    def stopRecording(self):
        self.__song__.get_metronome_manager().stop_recording()

    @Signal
    def sound_data_changed(self):
        pass

    def __read_metadata__(self):
        try:
            self.audio_metadata = taglib.File(self.__path__).tags

            if self.__bpm__ <= 0:
                self.set_bpm(int(self.audio_metadata["ZYNTHBOX_BPM"][0]), True)

            self.sound_data_changed.emit()
            self.metadata_bpm_changed.emit()
        except Exception as e:
            logging.error(f"Cannot read metadata : {str(e)}")
            self.audio_metadata = None

    def metadata(self):
        return self.audio_metadata

    def write_metadata(self, key, value: list):
        if self.__path__ is not None:
            try:
                file = taglib.File(self.__path__)
                file.tags[key] = value
                file.save()
            except Exception as e:
                logging.error(f"Error writing metadata : {str(e)}")

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
                logging.error(f"Error retrieving from metadata : {str(e)}")

        return data

    soundData = Property('QVariantList', get_soundData, notify=sound_data_changed)

    @Signal
    def sec_per_beat_changed(self):
        pass

    def get_secPerBeat(self):
        return 60.0/self.__song__.bpm

    secPerBeat = Property(float, get_secPerBeat, notify=sec_per_beat_changed)

    @Signal
    def metadata_bpm_changed(self):
        pass

    def get_metadataBPM(self):
        try:
            return int(self.audio_metadata["ZYNTHBOX_BPM"][0])
        except Exception as e:
            logging.error(f"Error retrieving from metadata : {str(e)}")

        return None

    metadataBPM = Property(int, get_metadataBPM, notify=metadata_bpm_changed)
