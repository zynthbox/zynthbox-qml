#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthiloops Song: An object to store song information
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
import ctypes as ctypes
import math

from PySide2.QtCore import Qt, Property, QObject, Signal, Slot

from . import libzl
from .zynthiloops_track import zynthiloops_track
from .zynthiloops_part import zynthiloops_part
from .zynthiloops_clip import zynthiloops_clip
from .zynthiloops_parts_model import zynthiloops_parts_model
from .zynthiloops_tracks_model import zynthiloops_tracks_model

import logging
import json
from pathlib import Path


class zynthiloops_song(QObject):
    __instance__ = None

    def __init__(self, parent=None):
        super(zynthiloops_song, self).__init__(parent)

        self.__metronome_manager__ = parent

        self.__sketch_folder__ = "/zynthian/zynthian-my-data/sketches/"
        self.__sketch_filename__ = "sketch1.json"
        self.__tracks_model__ = zynthiloops_tracks_model(self)
        self.__parts_model__ = zynthiloops_parts_model(self)
        self.__bpm__ = 120
        self.__index__ = 0
        self.__is_playing__ = False
        self.__name__ = f"Song {self.__index__+1}"

        self.__current_bar__ = 0
        self.__current_part__ = self.__parts_model__.getPart(0)

        if not self.restore():
            # Add default parts
            for i in range(0, 2):
                self.__parts_model__.add_part(zynthiloops_part(i, self))

            track = zynthiloops_track(self.__tracks_model__.count, self, self.__tracks_model__)
            self.__tracks_model__.add_track(track)
            for i in range(0, 2):
                clip = zynthiloops_clip(track.id, i, self, track.clipsModel)
                track.clipsModel.add_clip(clip)
                #self.add_clip_to_part(clip, i)


    def serialize(self):
        return {"name": self.__name__,
                "bpm": self.__bpm__,
                "tracks": self.__tracks_model__.serialize(),
                "parts": self.__parts_model__.serialize()}

    def save(self):
        try:
            Path(self.__sketch_folder__).mkdir(parents=True, exist_ok=True)
            f = open(self.__sketch_folder__ + self.__sketch_filename__, "w")
            f.write(json.dumps(self.serialize()))
            f.close()
        except Exception as e:
            logging.error(e)

    def restore(self):
        # try:
        #     f = open(self.__sketch_folder__ + self.__sketch_filename__, "r")
        #     obj = json.loads(f.read())
        #     logging.error("BBBBB")
        #     logging.error(obj["tracks"])
        #     logging.error(obj["parts"])
        #
        #     if "name" in obj:
        #         self.__name__ = obj["name"]
        #     if "bpm" in obj:
        #         self.__bpm__ = obj["bpm"]
        #     if "parts" in obj:
        #         self.__parts_model__.deserialize(obj["parts"])
        #     if "tracks" in obj:
        #         self.__tracks_model__.deserialize(obj["tracks"])
        #     return True
        # except Exception as e:
        #     logging.error(e)
        #     return False
        return False

    def get_metronome_manager(self):
        return self.__metronome_manager__

    @Property(bool, constant=True)
    def playable(self):
        return False

    @Property(bool, constant=True)
    def recordable(self):
        return False

    @Property(bool, constant=True)
    def clearable(self):
        return False

    @Property(bool, constant=True)
    def deletable(self):
        return False

    @Property(bool, constant=True)
    def nameEditable(self):
        return True

    @Signal
    def __name_changed__(self):
        pass

    @Property(str, notify=__name_changed__)
    def name(self):
        return self.__name__

    @name.setter
    def set_name(self, name):
        self.__name__ = name
        self.__name_changed__.emit()

    @Signal
    def bpm_changed(self):
        pass

    @Signal
    def index_changed(self):
        pass

    @Signal
    def __is_playing_changed__(self):
        pass

    @Signal
    def current_beat_changed(self):
        pass

    @Signal
    def __tracks_model_changed__(self):
        pass

    @Signal
    def __parts_model_changed__(self):
        pass

    @Property(QObject, notify=__tracks_model_changed__)
    def tracksModel(self):
        return self.__tracks_model__

    @Property(QObject, notify=__parts_model_changed__)
    def partsModel(self):
        return self.__parts_model__

    @Property(bool, notify=__is_playing_changed__)
    def isPlaying(self):
        return self.__is_playing__

    @Slot(None)
    def addTrack(self):
        track = zynthiloops_track(self.__tracks_model__.count, self, self.__tracks_model__)
        self.__tracks_model__.add_track(track)
        for i in range(0, 2): #TODO: keep numer of parts consistent
            clip = zynthiloops_clip(track.id, i, self, track.clipsModel)
            track.clipsModel.add_clip(clip)
            #self.add_clip_to_part(clip, i)
        self.save()

    @Property(int, notify=bpm_changed)
    def bpm(self):
        return self.__bpm__

    @bpm.setter
    def set_bpm(self, bpm: int):
        self.__bpm__ = bpm
        self.bpm_changed.emit()

    @Property(int, notify=index_changed)
    def index(self):
        return self.__index__

    @index.setter
    def set_index(self, index):
        self.__index__ = index
        self.index_changed.emit()

    # def add_clip_to_part(self, clip, part_index):
    #     self.__parts_model__.getPart(part_index).add_clip(clip)
