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
import traceback
import uuid

from PySide2.QtCore import Qt, QTimer, Property, QObject, Signal, Slot

from . import libzl
from .zynthiloops_scenes_model import zynthiloops_scenes_model
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

    def __init__(self, sketch_folder: str, name, parent=None, suggested_name=None):
        super(zynthiloops_song, self).__init__(parent)

        self.__metronome_manager__ = parent

        self.sketch_folder = sketch_folder
        self.__tracks_model__ = zynthiloops_tracks_model(self)
        self.__parts_model__ = zynthiloops_parts_model(self)
        self.__scenes_model__ = zynthiloops_scenes_model(self)
        self.__bpm__ = 120
        self.__volume__ = 100
        self.__index__ = 0
        self.__is_playing__ = False
        self.__save_timer__ = QTimer(self)
        self.__save_timer__.setInterval(1000)
        self.__save_timer__.setSingleShot(True)
        self.__save_timer__.timeout.connect(self.save)
        self.__history_length__ = 0
        self.__scale_model__ = ['C', 'G', 'D', 'A', 'E', 'B', 'Gb', 'Db', 'Ab', 'Eb', 'Bb', 'F']
        self.__selected_scale_index__ = 0

        self.__current_bar__ = 0
        self.__current_part__ = self.__parts_model__.getPart(0)
        self.__name__ = name
        self.__suggested_name__ = suggested_name
        self.__initial_name__ = name # To be used while storing cache details when name changes
        self.__to_be_deleted__ = False

        if not self.restore():
            # Add default parts
            for i in range(0, 10):
                self.__parts_model__.add_part(zynthiloops_part(i, self))

            for _ in range(0, 10):
                track = zynthiloops_track(self.__tracks_model__.count, self, self.__tracks_model__)
                self.__tracks_model__.add_track(track)
                for i in range(0, 10):
                    clip = zynthiloops_clip(track.id, i, self, track.clipsModel)
                    track.clipsModel.add_clip(clip)
                    self.__scenes_model__.addClipToScene(clip, i)
        self.bpm_changed.emit()

        # Create wav dir for recording
        (Path(self.sketch_folder) / 'wav').mkdir(parents=True, exist_ok=True)
        # Create root samples dir if not exists
        (Path(self.sketch_folder) / 'samples').mkdir(parents=True, exist_ok=True)

    def to_be_deleted(self):
        self.__to_be_deleted__ = True

    def serialize(self):
        return {"name": self.__name__,
                "suggestedName": self.__suggested_name__,
                "bpm": self.__bpm__,
                "volume": self.__volume__,
                "selectedScaleIndex": self.__selected_scale_index__,
                "tracks": self.__tracks_model__.serialize(),
                "parts": self.__parts_model__.serialize(),
                "scenes": self.__scenes_model__.serialize()}

    def save(self, cache=True):
        if self.__to_be_deleted__:
            return

        cache_dir = Path(self.sketch_folder) / ".cache"
        cache_dir.mkdir(parents=True, exist_ok=True)

        if self.isTemp or not cache:
            if not self.isTemp:
                # Clear previous history and remove cache files if not temp
                with open(self.sketch_folder + self.__initial_name__ + ".sketch.json", "r+") as f:
                    obj = json.load(f)
                    f.seek(0)

                    if "history" in obj and len(obj["history"]) > 0:
                        for history in obj["history"]:
                            try:
                                Path(cache_dir / (history + ".sketch.json")).unlink()
                            except Exception as e:
                                logging.error(f"Error while trying to remove cache file .cache/{history}.sketch.json : {str(e)}")

                    obj["history"] = []
                    self.__history_length__ = 0
                    self.history_length_changed.emit()

                    json.dump(obj, f)
                    f.truncate()
                    f.flush()
                    os.fsync(f.fileno())

            filename = self.__name__ + ".sketch.json"
            self.__initial_name__ = self.name

            logging.error(f"Storing to {filename} : {self}")

            # Handle saving to sketch json file
            try:
                Path(self.sketch_folder).mkdir(parents=True, exist_ok=True)

                with open(self.sketch_folder + filename, "w") as f:
                    f.write(json.dumps(self.serialize()))
                    f.flush()
                    os.fsync(f.fileno())
            except Exception as e:
                logging.error(e)

            # Save snapshot with sketch if not temp
            if not self.isTemp:
                try:
                    soundsets_dir = Path(self.sketch_folder) / "soundsets"
                    soundsets_dir.mkdir(parents=True, exist_ok=True)

                    self.__metronome_manager__.zyngui.screens["layer"].save_snapshot(
                        str(soundsets_dir) + "/" + self.__name__ + ".zss")
                except Exception as e:
                    logging.error(f"Error saving snapshot to sketch folder : {str(e)}")

            self.versions_changed.emit()
        else:
            filename = self.__initial_name__ + ".sketch.json"

            # Handle saving to cache
            cache_id = str(uuid.uuid1())

            logging.error(f"Storing to cache {cache_id}.sketch.json")

            try:
                with open(self.sketch_folder + filename, "r+") as f:
                    obj = json.load(f)
                    f.seek(0)

                    comparing_obj = {}
                    if "history" in obj and len(obj["history"]) > 0:
                        with open(self.sketch_folder + filename, "r+") as f_last_cache:
                            comparing_obj = json.load(f_last_cache)
                    else:
                        comparing_obj = obj

                    comparing_obj.pop("history", None)

                    # logging.error(f"Comparing cache and saved dicts : {self.serialize()}")
                    # logging.error(f"Comparing cache and saved dicts : {comparing_obj}")
                    # logging.error(f"Comparing cache and saved dicts : {self.serialize() == comparing_obj}")

                    if self.serialize() != comparing_obj:
                        with open(cache_dir / (cache_id + ".sketch.json"), "w") as f_cache:
                            f_cache.write(json.dumps(self.serialize()))
                            f_cache.flush()
                            os.fsync(f_cache.fileno())

                        if "history" not in obj:
                            obj["history"] = []

                        obj["history"].append(cache_id)

                        self.__history_length__ = len(obj["history"])
                        self.history_length_changed.emit()

                        json.dump(obj, f)
                        f.truncate()
                        f.flush()
                        os.fsync(f.fileno())
            except Exception as e:
                logging.error(e)

    def schedule_save(self):
        self.__save_timer__.start()

    def restore(self):
        filename = self.__name__ + ".sketch.json"

        try:
            logging.error(f"Restoring {self.sketch_folder + filename}")
            with open(self.sketch_folder + filename, "r") as f:
                sketch = json.loads(f.read())

                if "history" in sketch and len(sketch["history"]) > 0:
                    cache_dir = Path(self.sketch_folder) / ".cache"
                    with open(cache_dir / (sketch["history"][-1] + ".sketch.json"), "r") as f_cache:
                        sketch = json.load(f_cache)

                if "name" in sketch:
                    self.__name__ = sketch["name"]
                if "suggestedName" in sketch:
                    self.__suggested_name__ = sketch["suggestedName"]
                    self.set_suggested_name(self.__suggested_name__, True)
                if "volume" in sketch:
                    self.__volume__ = sketch["volume"]
                    self.set_volume(self.__volume__, True)

                    # Restore ALSA Mixer volume from sketch
                    self.__metronome_manager__.zyngui.screens["master_alsa_mixer"].volume = self.__volume__
                if "selectedScaleIndex" in sketch:
                    self.set_selected_scale_index(sketch["selectedScaleIndex"], True)
                if "parts" in sketch:
                    self.__parts_model__.deserialize(sketch["parts"])
                if "tracks" in sketch:
                    self.__tracks_model__.deserialize(sketch["tracks"])
                if "scenes" in sketch:
                    self.__scenes_model__.deserialize(sketch["scenes"])
                if "bpm" in sketch:
                    self.__bpm__ = sketch["bpm"]
                    self.set_bpm(self.__bpm__, True)

                return True
        except Exception as e:
            logging.error(e)
            return False

    @Slot(int, int, result=QObject)
    def getClip(self, track: int, part: int):
        # logging.error("GETCLIP {} {} count {}".format(track, part, self.__tracks_model__.count))
        if track >= self.__tracks_model__.count:
            return None

        track = self.__tracks_model__.getTrack(track)
        # logging.error(track.clipsModel.count)

        if part >= track.clipsModel.count:
            return None

        clip = track.clipsModel.getClip(part)
        # logging.error(clip)
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
        versions = [f.name.replace(".sketch.json", "") for f in Path(self.sketch_folder).glob("*.sketch.json")]
        return versions

    versions = Property('QVariantList', get_versions, notify=versions_changed)

    @Signal
    def is_temp_changed(self):
        pass

    def get_isTemp(self):
        return self.sketch_folder == str(Path("/zynthian/zynthian-my-data/sketches/my-sketches/") / "temp") + "/"

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
            self.schedule_save()

    name = Property(str, name, set_name, notify=__name_changed__)


    @Signal
    def volume_changed(self):
        pass

    def get_volume(self):
        return self.__volume__

    def set_volume(self, volume:int, force_set=False):
        if self.__volume__ != math.floor(volume) or force_set is True:
            self.__volume__ = math.floor(volume)
            self.volume_changed.emit()
            self.schedule_save()

    volume = Property(int, get_volume, set_volume, notify=volume_changed)


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
    def tracks_model_changed(self):
        pass

    @Signal
    def __parts_model_changed__(self):
        pass

    @Signal
    def __scenes_model_changed__(self):
        pass

    def tracksModel(self):
        return self.__tracks_model__
    tracksModel = Property(QObject, tracksModel, notify=tracks_model_changed)

    def partsModel(self):
        return self.__parts_model__
    partsModel = Property(QObject, partsModel, notify=__parts_model_changed__)

    def scenesModel(self):
        return self.__scenes_model__
    scenesModel = Property(QObject, scenesModel, notify=__scenes_model_changed__)

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
        self.schedule_save()

    def bpm(self):
        return self.__bpm__

    def set_bpm(self, bpm: int, force_set=False):
        if self.__bpm__ != math.floor(bpm) or force_set is True:
            self.__bpm__ = math.floor(bpm)
            self.bpm_changed.emit()
            self.schedule_save()

    bpm = Property(int, bpm, set_bpm, notify=bpm_changed)


    def index(self):
        return self.__index__

    def set_index(self, index):
        self.__index__ = index
        self.index_changed.emit()

    index = Property(int, index, set_index, notify=index_changed)


    @Signal
    def history_length_changed(self):
        pass

    def get_history_length(self):
        return self.__history_length__

    historyLength = Property(int, get_history_length, notify=history_length_changed)

    @Slot(None)
    def undo(self):
        cache_dir = Path(self.sketch_folder) / ".cache"

        try:
            with open(self.sketch_folder + self.__initial_name__ + ".sketch.json", "r+") as f:
                obj = json.load(f)
                f.seek(0)

                if "history" in obj and len(obj["history"]) > 0:
                    cache_file = obj["history"].pop()

                try:
                    Path(cache_dir / (cache_file + ".sketch.json")).unlink()
                except:
                    pass

                self.__history_length__ = len(obj["history"])
                self.history_length_changed.emit()

                json.dump(obj, f)
                f.truncate()
                f.flush()
                os.fsync(f.fileno())
        except Exception as e:
            logging.error(e)
            return False

        self.__metronome_manager__.loadSketchVersion(self.__initial_name__)

    ### Property scaleModel
    def get_scale_model(self):
        return self.__scale_model__
    scaleModel = Property('QVariantList', get_scale_model, constant=True)
    ### END Property scaleModel

    ### Property selectedScaleIndex
    def get_selected_scale_index(self):
        return self.__selected_scale_index__
    def set_selected_scale_index(self, index, force_set=False):
        if self.__selected_scale_index__ != index or force_set is True:
            self.__selected_scale_index__ = index
            self.selected_scale_index_changed.emit()
            self.schedule_save()
    selected_scale_index_changed = Signal()
    selectedScaleIndex = Property(int, get_selected_scale_index, set_selected_scale_index, notify=selected_scale_index_changed)
    ### END Property selectedScaleIndex

    ### Property selectedScale
    def get_selected_scale(self):
        return self.__scale_model__[self.__selected_scale_index__]
    selectedScale = Property(str, get_selected_scale, notify=selected_scale_index_changed)
    ### END Property selectedScale

    ### Property sketchFolderName
    def get_sketch_folder_name(self):
        return Path(self.sketch_folder).stem
    sketchFolderName = Property(str, get_sketch_folder_name, constant=True)
    ### END Property sketchFolderName

    ### Property sketchFolder
    def get_sketch_folder(self):
        return self.sketch_folder
    sketchFolder = Property(str, get_sketch_folder, constant=True)
    ### END Property sketchFolder

    ### Property suggestedName
    def get_suggested_name(self):
        return self.__suggested_name__
    def set_suggested_name(self, suggested_name, force_set=False):
        if self.__suggested_name__ != suggested_name or force_set is True:
            self.__suggested_name__ = suggested_name
            self.suggested_name_changed.emit()
    suggested_name_changed = Signal()
    suggestedName = Property(str, get_suggested_name, set_suggested_name, notify=suggested_name_changed)
    ### End Property suggestedName

    def stop(self):
        for i in range(0, self.__parts_model__.count):
            part = self.__parts_model__.getPart(i)
            part.stop()
