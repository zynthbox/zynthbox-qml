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

from PySide2.QtCore import Qt, QTimer, Property, QObject, Signal, Slot

from . import libzl
from .zynthiloops_track import zynthiloops_track
from .zynthiloops_part import zynthiloops_part
from .zynthiloops_clip import zynthiloops_clip
from .zynthiloops_parts_model import zynthiloops_parts_model
from .zynthiloops_tracks_model import zynthiloops_tracks_model

import logging
import json
import os
from pathlib import Path


class zynthiloops_song(QObject):
    __instance__ = None

    def __init__(self, sketch_folder: str, name, parent=None):
        super(zynthiloops_song, self).__init__(parent)

        self.__metronome_manager__ = parent

        self.sketch_folder = sketch_folder
        self.sketch_filename = "sketch.json"
        self.__tracks_model__ = zynthiloops_tracks_model(self)
        self.__parts_model__ = zynthiloops_parts_model(self)
        self.__bpm__ = 120
        self.__index__ = 0
        self.__is_playing__ = False
        self.__save_timer__ = QTimer(self)
        self.__save_timer__.setInterval(1000)
        self.__save_timer__.setSingleShot(True)
        self.__save_timer__.timeout.connect(self.save)

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

        self.name = name
        self.bpm_changed.emit()

    def serialize(self):
        return {"name": self.__name__,
                "bpm": self.__bpm__,
                "tracks": self.__tracks_model__.serialize(),
                "parts": self.__parts_model__.serialize()}

    def save(self):
        obj = {}

        try:
            with open(self.sketch_folder + self.sketch_filename, "r") as f:
                obj = json.loads(f.read())
        except Exception as e:
            logging.error(e)

        try:
            Path(self.sketch_folder).mkdir(parents=True, exist_ok=True)

            with open(self.sketch_folder + self.sketch_filename, "w") as f:
                obj["selected_version"] = f"{self.__name__}"

                if "versions" in obj:
                    obj["versions"][f"{self.__name__}"] = self.serialize()
                else:
                    obj["versions"] = {
                        f"{self.__name__}": self.serialize()
                    }

                logging.error(f"### {obj}")
                f.write(json.dumps(obj))

            print(self.sketch_folder + self.sketch_filename)
        except Exception as e:
            logging.error(e)

        self.versions_changed.emit()

    def schedule_save(self):
        self.__save_timer__.start()


    def restore(self):
        try:
            logging.error(f"Restoring {self.sketch_folder + self.sketch_filename}")
            with open(self.sketch_folder + self.sketch_filename, "r") as f:
                obj = json.loads(f.read())
                sketch = obj["versions"][obj["selected_version"]]

                if "name" in sketch:
                    self.__name__ = sketch["name"]
                if "bpm" in sketch:
                    self.__bpm__ = sketch["bpm"]
                    self.set_bpm(self.__bpm__, True)
                if "parts" in sketch:
                    self.__parts_model__.deserialize(sketch["parts"])
                if "tracks" in sketch:
                    self.__tracks_model__.deserialize(sketch["tracks"])

                return True
        except Exception as e:
            logging.error(e)
            return False

    def destroy(self):
        for i in range(0, self.tracksModel.count):
            clipsModel = self.tracksModel.getTrack(i).clipsModel

            for clip_index in range(0, clipsModel.count):
                clip: zynthiloops_clip = clipsModel.getClip(clip_index)

                logging.error(f"Destroying clip({clip})")
                clip.destroy()

        os.remove(self.sketch_folder + self.sketch_filename)
        self.deleteLater()

    @Slot(int, int, result=QObject)
    def getClip(self, track: int, part: int):
        logging.error("GETCLIP {} {} count {}".format(track, part, self.__tracks_model__.count))
        if track >= self.__tracks_model__.count:
            return None

        track = self.__tracks_model__.getTrack(track)
        logging.error(track.clipsModel.count)

        if part >= track.clipsModel.count:
            return None

        clip = track.clipsModel.getClip(part)
        logging.error(clip)
        return clip


    def get_metronome_manager(self):
        return self.__metronome_manager__

    def playable(self):
        return False
    playable = Property(bool, playable, constant=True)

    def recordable(self):
        return False
    recordable = Property(bool, recordable, constant=True)

    def clearable(self):
        return False
    clearable = Property(bool, clearable, constant=True)

    def deletable(self):
        return False
    deletable = Property(bool, deletable, constant=True)

    def nameEditable(self):
        return True
    nameEditable = Property(bool, nameEditable, constant=True)

    @Signal
    def versions_changed(self):
        pass

    def get_versions(self):
        versions = []

        try:
            f = open(self.sketch_folder + self.sketch_filename, "r")
            obj = json.loads(f.read())

            for name, sketch in obj["versions"].items():
                versions.append(name)
        except Exception as e:
            logging.error(e)

        return versions

    versions = Property('QVariantList', get_versions, notify=versions_changed)

    @Signal
    def is_temp_changed(self):
        pass

    def get_isTemp(self):
        return self.sketch_folder == str(Path("/zynthian/zynthian-my-data/sketches/") / "temp") + "/"

    isTemp = Property(bool, get_isTemp, notify=is_temp_changed)

    @Signal
    def __name_changed__(self):
        pass


    def name(self):
        return self.__name__

    def set_name(self, name):
        if name is not None:
            self.__name__ = name
            self.__name_changed__.emit()
            self.is_temp_changed.emit()
            self.versions_changed.emit()
            # self.schedule_save()

    name = Property(str, name, set_name, notify=__name_changed__)


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

    def tracksModel(self):
        return self.__tracks_model__
    tracksModel = Property(QObject, tracksModel, notify=__tracks_model_changed__)


    def partsModel(self):
        return self.__parts_model__
    partsModel = Property(QObject, partsModel, notify=__parts_model_changed__)


    def isPlaying(self):
        return self.__is_playing__
    isPlaying = Property(bool, notify=__is_playing_changed__)

    @Slot(None)
    def addTrack(self):
        track = zynthiloops_track(self.__tracks_model__.count, self, self.__tracks_model__)
        self.__tracks_model__.add_track(track)
        for i in range(0, 2): #TODO: keep numer of parts consistent
            clip = zynthiloops_clip(track.id, i, self, track.clipsModel)
            track.clipsModel.add_clip(clip)
            #self.add_clip_to_part(clip, i)
        # self.schedule_save()

    def bpm(self):
        return self.__bpm__

    def set_bpm(self, bpm: int, force_set=False):
        if self.__bpm__ != math.floor(bpm) or force_set is True:
            self.__bpm__ = math.floor(bpm)
            self.bpm_changed.emit()
            # self.schedule_save()

    bpm = Property(int, bpm, set_bpm, notify=bpm_changed)


    def index(self):
        return self.__index__

    def set_index(self, index):
        self.__index__ = index
        self.index_changed.emit()

    index = Property(int, index, set_index, notify=index_changed)

    # def add_clip_to_part(self, clip, part_index):
    #     self.__parts_model__.getPart(part_index).add_clip(clip)
