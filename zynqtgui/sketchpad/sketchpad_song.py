#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Sketchpad Song: An object to store song information
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
import shutil
import traceback
import uuid

from PySide2.QtCore import Qt, QTimer, Property, QObject, Signal, Slot

import zynautoconnect
from zynqtgui.sketchpad.libzl import libzl
from .sketchpad_mix import sketchpad_mix
from .sketchpad_mixes_model import sketchpad_mixes_model
from .sketchpad_scenes_model import sketchpad_scenes_model
from .sketchpad_segment import sketchpad_segment
from .sketchpad_channel import sketchpad_channel
from .sketchpad_part import sketchpad_part
from .sketchpad_clip import sketchpad_clip
from .sketchpad_parts_model import sketchpad_parts_model
from .sketchpad_channels_model import sketchpad_channels_model

import logging
import json
import os
from pathlib import Path

from zynqtgui import zynthian_gui_config
from zynqtgui.zynthian_gui_config import zyngui


class sketchpad_song(QObject):
    __instance__ = None

    def __init__(self, sketchpad_folder: str, name, parent=None, load_history=True):
        super(sketchpad_song, self).__init__(parent)

        self.zyngui = zynthian_gui_config.zyngui
        self.__metronome_manager__ = parent
        self.sketchpad_folder = sketchpad_folder

        self.__is_loading__ = True
        self.isLoadingChanged.emit()
        self.__channels_model__ = sketchpad_channels_model(self)
        self.__parts_model__ = sketchpad_parts_model(self)
        self.__scenes_model__ = sketchpad_scenes_model(self)
        self.__mixes_model__ = sketchpad_mixes_model(self)
        self.__bpm__ = [120, 120, 120, 120, 120, 120, 120, 120, 120, 120]
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
        # The octave is -1 indexed, as we operate with C4 == midi note 60, so this makes our default a key of C2
        self.__octave__ = 2
        self.__play_channel_solo = -1

        self.__current_bar__ = 0
        self.__current_part__ = self.__parts_model__.getPart(0)
        self.__name__ = name
        self.__initial_name__ = name # To be used while storing cache details when name changes
        self.__to_be_deleted__ = False

        self.updateAutoconnectedSoundsThrottle = QTimer()
        self.updateAutoconnectedSoundsThrottle.setInterval(100)
        self.updateAutoconnectedSoundsThrottle.setSingleShot(True)
        self.updateAutoconnectedSoundsThrottle.timeout.connect(self.doUpdateAutoconnectedSounds)

        if not self.restore(load_history):
            self.__is_loading__ = True
            self.isLoadingChanged.emit()
            # First, clear out any cruft that might have occurred during a failed load attempt
            self.__parts_model__ = sketchpad_parts_model(self)
            self.__channels_model__ = sketchpad_channels_model(self)
            self.__scenes_model__ = sketchpad_scenes_model(self)
            self.__mixes_model__ = sketchpad_mixes_model(self)

            # Add default parts
            for i in range(0, 10):
                self.__parts_model__.add_part(sketchpad_part(i, self))

            for _ in range(0, 10):
                channel = sketchpad_channel(self.__channels_model__.count, self, self.__channels_model__)
                self.__channels_model__.add_channel(channel)

                # Create 5 parts per channel
                for i in range(0, 5):
                    clipsModel = channel.getClipsModelByPart(i)
                    for j in range(0, 10):
                        clip = sketchpad_clip(channel.id, j, i, self, clipsModel)
                        clipsModel.add_clip(clip)

            for channel_index in range(10):
                channel = self.__channels_model__.getChannel(channel_index)
                channel.getClipsModelByPart(0).getClip(0).enabled = True

            # Add default Mixes and Segments
            for mix_index in range(10):
                mix = sketchpad_mix(mix_index, self)
                segment = sketchpad_segment(mix, mix.segmentsModel, self)
                mix.segmentsModel.add_segment(0, segment)

                self.__mixes_model__.add_mix(mix_index, mix)

        self.bpm_changed.emit()
        # Emit bpm changed to get bpm of selectedMix
        self.__scenes_model__.selected_sketch_index_changed.connect(self.bpm_changed.emit)

        # Create wav dir for recording
        (Path(self.sketchpad_folder) / 'wav').mkdir(parents=True, exist_ok=True)
        # Create sampleset dir if not exists
        (Path(self.sketchpad_folder) / 'wav' / 'sampleset').mkdir(parents=True, exist_ok=True)
        # Finally, just in case something happened, make sure we're not loading any longer
        self.__is_loading__ = False
        self.isLoadingChanged.emit()

        # Schedule a save after a sketchpad loads/restores to ensure sketchpad file is available after creating a new sketchpad
        self.schedule_save()

    ###
    # Sometimes you just need to force-update the graph layout. Call this function to make that happen kind of soonish
    @Slot(None)
    def updateAutoconnectedSounds(self):
        self.updateAutoconnectedSoundsThrottle.start()

    @Slot(None)
    def doUpdateAutoconnectedSounds(self):
        zynautoconnect.audio_autoconnect(True)

    def to_be_deleted(self):
        self.__to_be_deleted__ = True

    def serialize(self):
        return {
            "name": self.__name__,
            "bpm": self.__bpm__,
            "volume": self.__volume__,
            "selectedScaleIndex": self.__selected_scale_index__,
            "octave": self.__octave__,
            "channels": self.__channels_model__.serialize(),
            "parts": self.__parts_model__.serialize(),
            "scenes": self.__scenes_model__.serialize(),
            "mixes": self.__mixes_model__.serialize()
        }

    def save(self, cache=True):
        if self.__to_be_deleted__:
            return

        cache_dir = Path(self.sketchpad_folder) / ".cache"
        cache_dir.mkdir(parents=True, exist_ok=True)

        if self.isTemp or not cache:
            if not self.isTemp:
                # Clear previous history and remove cache files if not temp
                with open(self.sketchpad_folder + self.__initial_name__ + ".sketchpad.json", "r+") as f:
                    obj = json.load(f)
                    f.seek(0)

                    if "history" in obj and len(obj["history"]) > 0:
                        for history in obj["history"]:
                            try:
                                Path(cache_dir / (history + ".sketchpad.json")).unlink()
                            except Exception as e:
                                logging.error(f"Error while trying to remove cache file .cache/{history}.sketchpad.json : {str(e)}")

                    obj["history"] = []
                    self.__history_length__ = 0
                    self.history_length_changed.emit()

                    json.dump(obj, f)
                    f.truncate()
                    f.flush()
                    os.fsync(f.fileno())

            filename = self.__name__ + ".sketchpad.json"
            self.__initial_name__ = self.name

            logging.info(f"Storing to {filename} : {self}")

            # Handle saving to sketchpad json file
            try:
                Path(self.sketchpad_folder).mkdir(parents=True, exist_ok=True)

                with open(self.sketchpad_folder + filename, "w") as f:
                    f.write(json.dumps(self.serialize()))
                    f.flush()
                    os.fsync(f.fileno())
            except Exception as e:
                logging.error(e)

            # Save snapshot with sketchpad if not temp
            if not self.isTemp:
                try:
                    soundsets_dir = Path(self.sketchpad_folder) / "soundsets"
                    soundsets_dir.mkdir(parents=True, exist_ok=True)

                    self.__metronome_manager__.zyngui.screens["layer"].save_snapshot(
                        str(soundsets_dir) + "/" + self.__name__ + ".zss")
                except Exception as e:
                    logging.error(f"Error saving snapshot to sketchpad folder : {str(e)}")

            self.versions_changed.emit()
        else:
            filename = self.__initial_name__ + ".sketchpad.json"

            # Handle saving to cache
            cache_id = str(uuid.uuid1())

            logging.info(f"Storing to cache {cache_id}.sketchpad.json")

            try:
                with open(self.sketchpad_folder + filename, "r+") as f:
                    obj = json.load(f)
                    f.seek(0)

                    comparing_obj = {}
                    if "history" in obj and len(obj["history"]) > 0:
                        with open(self.sketchpad_folder + filename, "r+") as f_last_cache:
                            comparing_obj = json.load(f_last_cache)
                    else:
                        comparing_obj = obj

                    comparing_obj.pop("history", None)

                    # logging.error(f"Comparing cache and saved dicts : {self.serialize()}")
                    # logging.error(f"Comparing cache and saved dicts : {comparing_obj}")
                    # logging.error(f"Comparing cache and saved dicts : {self.serialize() == comparing_obj}")

                    if self.serialize() != comparing_obj:
                        with open(cache_dir / (cache_id + ".sketchpad.json"), "w") as f_cache:
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

    @Slot(None)
    def schedule_save(self):
        if self.__is_loading__ is False:
            self.__save_timer__.start()

    def restore(self, load_history):
        self.__is_loading__ = True
        self.isLoadingChanged.emit()
        filename = self.__name__ + ".sketchpad.json"

        self.zyngui.currentTaskMessage = f"Restoring sketchpad"

        try:
            logging.info(f"Restoring {self.sketchpad_folder + filename}, loadHistory({load_history})")
            with open(self.sketchpad_folder + filename, "r") as f:
                sketchpad = json.loads(f.read())

                try:
                    cache_dir = Path(self.sketchpad_folder) / ".cache"

                    if load_history and "history" in sketchpad and len(sketchpad["history"]) > 0:
                        logging.info("Loading History")
                        with open(cache_dir / (sketchpad["history"][-1] + ".sketchpad.json"), "r") as f_cache:
                            sketchpad = json.load(f_cache)
                    else:
                        logging.info("Not loading History")
                        for history in sketchpad["history"]:
                            try:
                                Path(cache_dir / (history + ".sketchpad.json")).unlink()
                            except Exception as e:
                                logging.error(
                                    f"Error while trying to remove cache file .cache/{history}.sketchpad.json : {str(e)}")

                        sketchpad["history"] = []
                except:
                    logging.error(f"Error loading cache file. Continuing with sketchpad loading")

                if "name" in sketchpad and sketchpad["name"] != "":
                    if self.__name__ != sketchpad["name"]:
                        logging.info(f"Sketchpad filename changed from '{sketchpad['name']}' to '{self.__name__}'. "
                                      f"Trying to rename soundset file.")
                        logging.info(f'Renaming {self.sketchpad_folder}/soundsets/{sketchpad["name"]}.zss to {self.sketchpad_folder}/soundsets/{self.__name__}.zss')

                        try:
                            shutil.move(f'{self.sketchpad_folder}/soundsets/{sketchpad["name"]}.zss', f'{self.sketchpad_folder}/soundsets/{self.__name__}.zss')
                        except Exception as e:
                            logging.error(f"Error renaming old soundset to new name : {str(e)}")
                if "volume" in sketchpad:
                    self.__volume__ = sketchpad["volume"]
                    self.set_volume(self.__volume__, True)

                    # Restore ALSA Mixer volume from sketchpad
                    # self.__metronome_manager__.zyngui.screens["master_alsa_mixer"].volume = self.__volume__
                if "selectedScaleIndex" in sketchpad:
                    self.set_selected_scale_index(sketchpad["selectedScaleIndex"], True)
                if "octave" in sketchpad:
                    self.set_octave(sketchpad["octave"], True)
                if "parts" in sketchpad:
                    self.__parts_model__.deserialize(sketchpad["parts"])
                if "channels" in sketchpad:
                    self.__channels_model__.deserialize(sketchpad["channels"])
                if "scenes" in sketchpad:
                    self.__scenes_model__.deserialize(sketchpad["scenes"])
                if "mixes" in sketchpad:
                    self.__mixes_model__.deserialize(sketchpad["mixes"])
                if "bpm" in sketchpad:
                    # In older sketchpad files, bpm would still be an int instead of a list
                    # So if bpm is not a list, then generate a list and store it
                    if isinstance(sketchpad["bpm"], list):
                        self.__bpm__ = sketchpad["bpm"]
                    else:
                        self.__bpm__ = [120, 120, 120, 120, 120, 120, 120, 120, 120, 120]
                        self.__bpm__[self.__scenes_model__.selectedSketchIndex] = sketchpad["bpm"]

                    self.set_bpm(self.__bpm__[self.__scenes_model__.selectedSketchIndex], True)

                self.__is_loading__ = False
                self.isLoadingChanged.emit()
                return True
        except Exception as e:
            logging.error(f"Error during sketchpad restoration: {e}")
            traceback.print_exception(None, e, e.__traceback__)

            self.__is_loading__ = False
            self.isLoadingChanged.emit()
            return False

    @Slot(int, int, result=QObject)
    def getClip(self, channel: int, sketchpad: int):
        # logging.error("GETCLIP {} {} count {}".format(channel, part, self.__channels_model__.count))
        if channel >= self.__channels_model__.count:
            return None

        channel = self.__channels_model__.getChannel(channel)
        # logging.error(channel.clipsModel.count)

        if sketchpad >= channel.clipsModel.count:
            return None

        clip = channel.clipsModel.getClip(sketchpad)
        # logging.error(clip)
        return clip

    @Slot(int, int, result=QObject)
    def getClipByPart(self, channel: int, sketchpad: int, part: int):
        # logging.error("GETCLIP {} {} count {}".format(channel, part, self.__channels_model__.count))
        if channel >= self.__channels_model__.count:
            return None

        channel = self.__channels_model__.getChannel(channel)
        # logging.error(channel.clipsModel.count)

        if sketchpad >= channel.getClipsModelByPart(part).count:
            return None

        clip = channel.getClipsModelByPart(part).getClip(sketchpad)
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
        versions = [f.name.replace(".sketchpad.json", "") for f in Path(self.sketchpad_folder).glob("*.sketchpad.json")]
        return versions

    versions = Property('QVariantList', get_versions, notify=versions_changed)

    @Signal
    def is_temp_changed(self):
        pass

    def get_isTemp(self):
        return self.sketchpad_folder == str(Path("/zynthian/zynthian-my-data/sketchpads/my-sketchpads/") / "temp") + "/"

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
    def channels_model_changed(self):
        pass

    @Signal
    def __parts_model_changed__(self):
        pass

    @Signal
    def __scenes_model_changed__(self):
        pass

    def channelsModel(self):
        return self.__channels_model__
    channelsModel = Property(QObject, channelsModel, notify=channels_model_changed)

    def partsModel(self):
        return self.__parts_model__
    partsModel = Property(QObject, partsModel, notify=__parts_model_changed__)

    def scenesModel(self):
        return self.__scenes_model__
    scenesModel = Property(QObject, scenesModel, notify=__scenes_model_changed__)

    ### Property mixesModel
    def get_mixesModel(self):
        return self.__mixes_model__

    mixesModelChanged = Signal()

    mixesModel = Property(QObject, get_mixesModel, notify=mixesModelChanged)
    ### END Property mixesModel

    def isPlaying(self):
        return self.__is_playing__
    isPlaying = Property(bool, notify=__is_playing_changed__)

    # @Slot(None)
    # def addChannel(self):
    #     channel = sketchpad_channel(self.__channels_model__.count, self, self.__channels_model__)
    #     self.__channels_model__.add_channel(channel)
    #     for i in range(0, 2): #TODO: keep numer of parts consistent
    #         clip = sketchpad_clip(channel.id, i, self, channel.clipsModel)
    #         channel.clipsModel.add_clip(clip)
    #         #self.add_clip_to_part(clip, i)
    #     self.schedule_save()

    def bpm(self):
        return self.__bpm__[self.__scenes_model__.selectedSketchIndex]

    def set_bpm(self, bpm: int, force_set=False):
        if self.__bpm__[self.__scenes_model__.selectedSketchIndex] != math.floor(bpm) or force_set is True:
            self.__bpm__[self.__scenes_model__.selectedSketchIndex] = math.floor(bpm)

            # Update blink timer interval with change in bpm
            self.zyngui.wsleds_blink_timer.stop()
            self.zyngui.wsleds_blink_timer.setInterval(60000/(2*bpm))

            # Start blink timer only if metronome is not running
            # If metronome is running it is already blinking in sync with bpm
            if not self.zyngui.sketchpad.isMetronomeRunning:
                self.zyngui.wsleds_blink_timer.start()

            libzl.setBpm(self.__bpm__[self.__scenes_model__.selectedSketchIndex])
            # Call zyngui global set_selector when bpm changes as bpm is controlled by Big Knob
            # when global popup is opened
            self.zyngui.set_selector()

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
        cache_dir = Path(self.sketchpad_folder) / ".cache"

        try:
            with open(self.sketchpad_folder + self.__initial_name__ + ".sketchpad.json", "r+") as f:
                obj = json.load(f)
                f.seek(0)

                if "history" in obj and len(obj["history"]) > 0:
                    cache_file = obj["history"].pop()

                try:
                    Path(cache_dir / (cache_file + ".sketchpad.json")).unlink()
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

        self.__metronome_manager__.loadSketchpadVersion(self.__initial_name__)

    ### Property metronomeManager
    def get_metronomeManager(self):
        return self.__metronome_manager__

    metronomeManager = Property(QObject, get_metronomeManager, constant=True)
    ### END Property metronomeManager

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

    ### Property octave
    # The octave is -1 indexed, as we operate with C4 == midi note 60
    # The song's octave can be combined with the scaleIndex to work out what the song's key is as a midi note value:
    # Multiply the octave's value plus one with twelve, and add the scaleIndex, or:
    # (octave + 1) * 12 + scaleIndex
    def get_octave(self):
        return self.__octave__
    def set_octave(self, octave, force_set=False):
        if self.__octave__ != octave or force_set is True:
            self.__octave__ = octave
            if force_set is not True:
                self.octave_changed.emit()
                self.schedule_save()
    octave_changed = Signal()
    octave = Property(int, get_octave, set_octave, notify=octave_changed)
    ### END Property octave

    ### Property sketchpadFolderName
    def get_sketchpad_folder_name(self):
        return Path(self.sketchpad_folder).stem
    sketchpadFolderName = Property(str, get_sketchpad_folder_name, constant=True)
    ### END Property sketchpadFolderName

    ### Property sketchpadFolder
    def get_sketchpad_folder(self):
        return self.sketchpad_folder
    sketchpadFolder = Property(str, get_sketchpad_folder, constant=True)
    ### END Property sketchpadFolder

    ### Property playChannelSolo
    def get_playChannelSolo(self):
        return self.__play_channel_solo

    def set_playChannelSolo(self, value):
        if self.__play_channel_solo != value:
            logging.debug(f"set_playChannelSolo: {value}")
            self.__play_channel_solo = value

            for channel_index in range(self.channelsModel.count):
                channel = self.channelsModel.getChannel(channel_index)
                if (value == -1 or channel.id == value) and not channel.muted:
                    channel.unmute_all_clips_in_channel()
                else:
                    channel.mute_all_clips_in_channel()

            self.playChannelSoloChanged.emit()

    playChannelSoloChanged = Signal()

    playChannelSolo = Property(int, get_playChannelSolo, set_playChannelSolo, notify=playChannelSoloChanged)
    ### END Property playChannelSolo

    ### Property isLoading
    def get_isLoading(self):
        return self.__is_loading__

    isLoadingChanged = Signal()

    isLoading = Property(bool, get_isLoading, notify=isLoadingChanged)
    ### END Property isLoading

    def stop(self):
        for i in range(0, self.__parts_model__.count):
            part = self.__parts_model__.getPart(i)
            part.stop()
