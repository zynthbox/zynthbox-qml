#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to for storing tracks in ZynthiLoops page
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
import logging
import math

from PySide2.QtCore import Property, QObject, Signal, Slot

from .zynthiloops_clips_model import zynthiloops_clips_model
from .zynthiloops_clip import zynthiloops_clip

class zynthiloops_track(QObject):
    # Possible Values : "audio", "video"
    __type__ = "audio"

    def __init__(self, id: int, song: QObject, parent: QObject = None):
        super(zynthiloops_track, self).__init__(parent)
        self.__id__ = id
        self.__name__ = None
        self.__song__ = song
        self.__initial_volume__ = 67
        self.__volume__ = self.__initial_volume__
        self.__audio_level__ = -40
        self.__clips_model__ = zynthiloops_clips_model(song, self)
        self.__layers_snapshot = []
        self.master_volume = (self.__song__.get_metronome_manager().get_master_volume() - 50)/50
        self.__song__.get_metronome_manager().master_volume_changed.connect(lambda: self.master_volume_changed())

    def master_volume_changed(self):
        self.master_volume = (self.__song__.get_metronome_manager().get_master_volume() - 50)/50

    def serialize(self):
        return {"name": self.__name__,
                "volume": self.__volume__,
                "clips": self.__clips_model__.serialize(),
                "layers_snapshot": self.__layers_snapshot}

    def deserialize(self, obj):
        if "name" in obj:
            self.__name__ = obj["name"]
        if "volume" in obj:
            self.__volume__ = obj["volume"]
            self.set_volume(self.__volume__, True)
        if "clips" in obj:
            self.__clips_model__.deserialize(obj["clips"])
        if "layers_snapshot" in obj:
            self.__layers_snapshot = obj["layers_snapshot"]
            self.sound_data_changed.emit()

    def set_layers_snapshot(self, snapshot):
        self.__layers_snapshot = snapshot
        self.sound_data_changed.emit()

    def get_layers_snapshot(self):
        return self.__layers_snapshot

    def playable(self):
        return False
    playable = Property(bool, playable, constant=True)

    def recordable(self):
        return False
    recordable = Property(bool, recordable, constant=True)

    def clearable(self):
        return True
    clearable = Property(bool, clearable, constant=True)

    def deletable(self):
        return False
    deletable = Property(bool, deletable, constant=True)

    def nameEditable(self):
        return True
    nameEditable = Property(bool, nameEditable, constant=True)

    def id(self):
        return self.__id__
    id = Property(int, id, constant=True)

    @Signal
    def sound_data_changed(self):
        pass

    def get_soundData(self):
        return self.__layers_snapshot
    soundData = Property('QVariantList', get_soundData, notify=sound_data_changed)


    @Slot(None)
    def clear(self):
        track = self.__song__.tracksModel.getTrack(self.__id__)
        clipsModel = track.clipsModel

        logging.error(f"Track {track} ClipsModel {clipsModel}")

        for clip_index in range(0, clipsModel.count):
            logging.error(f"Track {self.__id__} Clip {clip_index}")
            clip: zynthiloops_clip = clipsModel.getClip(clip_index)
            logging.error(
                f"Clip : clip.row({clip.row}), clip.col({clip.col}), clip({clip})")
            clip.clear()

    @Signal
    def __name_changed__(self):
        pass

    def name(self):
        if self.__name__ is None:
            return f"T{self.__id__ + 1}"
        else:
            return self.__name__

    def set_name(self, name):
        if name != f"T{self.__id__ + 1}":
            self.__name__ = name
            self.__name_changed__.emit()
            self.__song__.schedule_save()

    name = Property(str, name, set_name, notify=__name_changed__)


    @Signal
    def volume_changed(self):
        pass

    def get_volume(self):
        return self.__volume__

    def set_volume(self, volume:int, force_set=False):
        if self.__volume__ != math.floor(volume) or force_set is True:
            self.__volume__ = math.floor(volume)
            logging.error(f"Track : Setting volume {self.__volume__}")
            self.volume_changed.emit()
            self.__song__.schedule_save()

    volume = Property(int, get_volume, set_volume, notify=volume_changed)

    ### Property initialVolume
    def get_initial_volume(self):
        return self.__initial_volume__
    initialVolume = Property(int, get_initial_volume, constant=True)
    ### END Property initialVolume

    def type(self):
        return self.__type__
    type = Property(str, type, constant=True)

    def clipsModel(self):
        return self.__clips_model__
    clipsModel = Property(QObject, clipsModel, constant=True)

    @Slot(None)
    def delete(self):
        self.__song__.tracksModel.delete_track(self)

    def set_id(self, new_id):
        self.__id__ = new_id
        self.__name_changed__.emit()


    @Signal
    def audioLevelChanged(self):
        pass

    def get_audioLevel(self):
        return self.__audio_level__

    def set_audioLevel(self, leveldB):
        lower_limit = -40
        upper_limit = 20
        new_upper_limit = upper_limit - (1 - self.__volume__/100) * (upper_limit - lower_limit)

        if self.master_volume is not None:
            new_upper_limit = new_upper_limit - (1-self.master_volume) * (new_upper_limit - lower_limit)

        # Calculate new value wrt volume
        leveldB = self.map_range(leveldB, lower_limit, upper_limit, lower_limit, new_upper_limit)

        if leveldB < -40:
            self.__audio_level__ = -40
        else:
            self.__audio_level__ = leveldB

        self.audioLevelChanged.emit()

    audioLevel = Property(float, get_audioLevel, set_audioLevel, notify=audioLevelChanged)

    @Slot(None, result=bool)
    def isEmpty(self):
        is_empty = True

        for clip_index in range(0, self.__clips_model__.count):
            clip: zynthiloops_clip = self.__clips_model__.getClip(clip_index)
            if clip.path is not None and len(clip.path) > 0:
                is_empty = False
                break

        return is_empty

    # Helper method to map value from one range to another
    @staticmethod
    def map_range(sourceNumber, fromA, fromB, toA, toB):
        deltaA = fromB - fromA
        deltaB = toB - toA
        scale  = deltaB / deltaA
        negA   = -1 * fromA
        offset = (negA * scale) + toA
        finalNumber = (sourceNumber * scale) + offset

        return finalNumber
