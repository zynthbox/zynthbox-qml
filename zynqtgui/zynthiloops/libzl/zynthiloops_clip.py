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

from . import libzl
from PySide2.QtCore import Property, QObject, QThread, Signal, Slot

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
        self.__should_sync__ = False
        self.audioSource: ClipAudioSource = None

        self.__song__.bpm_changed.connect(lambda: self.song_bpm_changed())

    def song_bpm_changed(self):
        self.update_synced_values()

    def update_synced_values(self):
        if self.__should_sync__:
            logging.error(f"Song BPM : {self.__song__.bpm}")
            new_ratio = self.__song__.bpm / self.__bpm__
            logging.error(f"Song New Ratio : {new_ratio}")
            self.set_time(new_ratio)

            # Set length to recalculate loop time
            self.set_length(self.__length__)

    def serialize(self):
        return {"name": self.name,
                "path": self.__path__,
                "start": self.__start_position__,
                "length": self.__length__,
                "pitch": self.__pitch__,
                "time": self.__time__}

    def deserialize(self, obj):
        #if "name" in obj:
            #self.name = obj["name"]
        if "path" in obj:
            self.__path__ = obj["path"]
        if "start" in obj:
            self.__start_position__ = obj["start"]
        if "length" in obj:
            self.__length__ = obj["length"]
        if "pitch" in obj:
            self.__pitch__ = obj["pitch"]
        if "time" in obj:
            self.__time__ = obj["time"]

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

    def length(self):
        return self.__length__

    def set_length(self, length: int):
        self.__length__ = length
        self.length_changed.emit()

        if self.audioSource is not None:
            self.audioSource.set_length(min(self.duration - self.__start_position__, (60.0 / self.__song__.bpm) * self.__length__))
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
        return f"T{self.__row_index__}{chr(self.__col_index__+65)}"
    name = Property(str, name, constant=True)

    def startPosition(self):
        return self.__start_position__

    def set_start_position(self, position: float):
        self.__start_position__ = position
        self.start_position_changed.emit()
        if self.audioSource is None:
            return
        self.audioSource.set_start_position(position)

    startPosition = Property(float, startPosition, set_start_position, notify=start_position_changed)

    def duration(self):
        if self.audioSource is None:
            return 0.0
        return self.audioSource.get_duration()

    duration = Property(float, duration, notify=duration_changed)



    def pitch(self):
        return self.__pitch__

    def set_pitch(self, pitch: float):
        self.__pitch__ = pitch
        self.pitch_changed.emit()
        if self.audioSource is None:
            return
        self.audioSource.set_pitch(pitch)

    pitch = Property(int, pitch, set_pitch, notify=pitch_changed)


    def time(self):
        return self.__time__

    def set_time(self, time: float):
        self.__time__ = time
        self.time_changed.emit()
        if self.audioSource is None:
            return
        self.audioSource.set_speed_ratio(time)
    time = Property(float, time, set_time, notify=time_changed)


    def bpm(self):
        return self.__bpm__

    def set_bpm(self, bpm: int):
        self.__bpm__ = bpm
        self.bpm_changed.emit()

    bpm = Property(int, bpm, set_bpm, notify=bpm_changed)


    def shouldSync(self):
        return self.__should_sync__

    def set_shouldSync(self, shouldSync: bool):
        self.__should_sync__ = shouldSync
        self.should_sync_changed.emit()
        self.update_synced_values()

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
        self.audioSource = ClipAudioSource(path.encode('utf-8'))
        print(path)

        self.__length__ = 1
        self.__is_playing__ = False
        self.__start_position__ = 0.0
        self.__pitch__ = 0
        self.__time__ = 1
        self.__bpm__ = 0

        self.startPosition = self.__start_position__
        self.length = self.__length__
        self.pitch - self.__pitch__
        self.time = self.__time__

        self.audioSource.set_start_position(self.__start_position__)
        self.path_changed.emit()
        self.duration_changed.emit()
    path = Property(str, path, set_path, notify=path_changed)

    @Slot(None)
    def clear(self, loop=True):
        self.stop()
        self.audioSource = None
        self.__path__ = None
        self.path_changed.emit()

    @Slot(None)
    def play(self):
        if self.audioSource is None:
            return
        self.__song__.get_metronome_manager().start_metronome_request()
        self.__is_playing__ = True
        self.__is_playing_changed__.emit()
        self.audioSource.addClipToTimer()

    @Slot(None)
    def stop(self, loop=True):
        logging.error(f"Stopping Clip {self.audioSource}")

        if self.audioSource is None:
            return
        self.__song__.get_metronome_manager().stop_metronome_request()
        self.__is_playing__ = False
        self.__is_playing_changed__.emit()
        self.audioSource.stop()
