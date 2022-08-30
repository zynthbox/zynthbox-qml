#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian Synth Categories
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
import json
import logging
import os
import tempfile
import traceback
from pathlib import Path

from PySide2.QtCore import Property, QObject, QSortFilterProxyModel, Qt, Slot

from .sound_categories_sounds_model import sound_categories_sounds_model
from .sounds_model_sound_dto import sounds_model_sound_dto
from .. import zynthian_qt_gui_base


class zynthian_gui_sound_categories(zynthian_qt_gui_base.ZynGui):
    def __init__(self, parent=None):
        super(zynthian_gui_sound_categories, self).__init__(parent)
        self.__sounds_base_path__ = Path('/zynthian/zynthian-my-data/sounds')
        self.__community_sounds_path__ = self.__sounds_base_path__ / 'community-sounds'
        self.__my_sounds_path__ = self.__sounds_base_path__ / 'my-sounds'
        self.__sounds_model__ = sound_categories_sounds_model(self)

        self.__sound_type_filter_proxy_model__ = QSortFilterProxyModel()
        self.__sound_type_filter_proxy_model__.setSourceModel(self.__sounds_model__)
        self.__sound_type_filter_proxy_model__.setFilterRole(sound_categories_sounds_model.Roles.SoundTypeRole)
        self.__sound_type_filter_proxy_model__.setFilterCaseSensitivity(Qt.CaseInsensitive)
        self.__sound_type_filter_proxy_model__.setFilterFixedString("my-sounds")

        self.__sound_category_filter_proxy_model__ = QSortFilterProxyModel()
        self.__sound_category_filter_proxy_model__.setSourceModel(self.__sound_type_filter_proxy_model__)
        self.__sound_category_filter_proxy_model__.setFilterRole(sound_categories_sounds_model.Roles.CategoryRole)
        self.__sound_category_filter_proxy_model__.setFilterCaseSensitivity(Qt.CaseInsensitive)

        self.__sound_category_name_mapping__ = {
            "*": "All",
            "0": "Uncategorized",
            "1": "Drums",
            "2": "Bass",
            "3": "Leads",
            "4": "Synth/Keys",
            "5": "Strings/Pads",
            "99": "FX/Other",
        }

        self.load_sounds_model()

    def show(self):
        pass

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    # def move_sound_category(self, sound, toCategory):
    #     if sound.type == "community-sounds":
    #         self.save_category(self.__community_sounds_path__ / sound.name, toCategory)
    #     elif sound.type == "my-sounds":
    #         self.save_category(self.__my_sounds_path__ / sound.name, toCategory)

    # Returns the category index if found otherwise returns 0 for uncategorized entries
    @staticmethod
    def get_category_for_sound(sound_file):
        category = "0"

        with open(sound_file, "r") as file:
            sound_json = json.load(file)
            try:
                category = sound_json["category"]
            except: pass

        return category

    @Slot(str, result=str)
    def getCategoryNameFromKey(self, key):
        try:
            return self.__sound_category_name_mapping__[key]
        except Exception as e:
            logging.debug(f"Sound Category with key `{key}` not found : {str(e)}")
            return ""

    @Slot()
    def load_sounds_model(self):
        def task():
            # Fill community-sounds list
            for file in self.__community_sounds_path__.glob("**/*.sound"):
                self.__sounds_model__.add_sound(
                    sounds_model_sound_dto(
                        self,
                        self.zyngui,
                        file.name,
                        "community-sounds",
                        self.get_category_for_sound(file)
                    )
                )

            # Fill my-sounds list
            for file in self.__my_sounds_path__.glob("**/*.sound"):
                self.__sounds_model__.add_sound(
                    sounds_model_sound_dto(
                        self,
                        self.zyngui,
                        file.name,
                        "my-sounds",
                        self.get_category_for_sound(file)
                    )
                )

            self.zyngui.end_long_task()

        self.zyngui.currentTaskMessage = "Reading and sorting sounds into categories"
        self.__sounds_model__.clear()
        self.zyngui.do_long_task(task)

    @Slot(str)
    def setSoundTypeFilter(self, _filter):
        self.__sound_type_filter_proxy_model__.setFilterFixedString(_filter)

    @Slot(str)
    def setCategoryFilter(self, _filter):
        # If qml sends category filter as `*`, clear any filtering and display all sounds
        if _filter == "*":
            self.__sound_category_filter_proxy_model__.setFilterRegExp("")
        else:
            self.__sound_category_filter_proxy_model__.setFilterFixedString(f"{_filter}")

    # Return an array of 5 elements with sound name if available or empty string
    @Slot(str, result='QVariantList')
    def getSoundNamesFromSoundFile(self, path):
        metadata = self.zyngui.layer.sound_metadata_from_file(path)
        res = []

        for layer in metadata:
            if "engine_type" in layer:
                if layer["engine_type"] != "Audio Effect":
                    if "preset_name" in layer:
                        res.append(f"{layer['name']} > {layer['preset_name']}")
                    else:
                        res.append(layer['name'])
            else:
                res.append(layer['name'])

        if len(res) < 5:
            for i in range(5 - len(res)):
                res.append("")

        return res[:5]

    @Slot(str, result=bool)
    def checkIfSoundFileExists(self, filename):
        return len(list(self.__my_sounds_path__.glob(f"**/{filename}.*.sound"))) > 0

    @Slot(str, str)
    def saveSound(self, filename, category):
        final_name = self.zyngui.layer.save_curlayer_to_file(str(self.__my_sounds_path__ / filename), category)

        if final_name is not None:
            logging.info(f"Saved sound file to {str(self.__my_sounds_path__ / filename)}")
        else:
            logging.error("Error saving sound file")

        self.load_sounds_model()

    @Slot(QObject)
    def loadSound(self, sound):
        self.loadSoundFromFile(sound.path)

    @Slot(int, str)
    def loadChannelSoundFromJson(self, channelIndex, soundJson):
        tempSoundJson = tempfile.NamedTemporaryFile(suffix=f".Ch{channelIndex+1}.sound", delete=False)
        sound_path = tempSoundJson.name

        try:
            tempSoundJson.write(bytes(soundJson, encoding='utf8'))
            tempSoundJson.flush()
            os.fsync(tempSoundJson.fileno())
        except: pass
        finally:
            tempSoundJson.close()

        self.loadSoundFromFile(sound_path, channelIndex)

    @Slot(str)
    def loadSoundFromFile(self, filepath, channelIndex=-1):
        def task():
            logging.debug(f"### Loading sound : {filepath}")

            if channelIndex == -1:
                channel = self.zyngui.zynthiloops.song.channelsModel.getChannel(self.zyngui.session_dashboard.selectedChannel)
            else:
                channel = self.zyngui.zynthiloops.song.channelsModel.getChannel(channelIndex)

            source_channels = self.zyngui.layer.load_layer_channels_from_file(filepath)
            free_layers = channel.getFreeLayers()
            used_layers = []

            for i in channel.chainedSounds:
                if i >= 0 and channel.checkIfLayerExists(i):
                    used_layers.append(i)

            logging.debug(f"### Before Removing")
            logging.debug(f"# Selected Channel         : {self.zyngui.session_dashboard.selectedChannel}")
            logging.debug(f"# Source Channels        : {source_channels}")
            logging.debug(f"# Free Layers            : {free_layers}")
            logging.debug(f"# Used Layers            : {used_layers}")
            logging.debug(f"# Chained Sounds         : {channel.chainedSounds}")
            logging.debug(f"# Source Channels Count  : {len(source_channels)}")
            logging.debug(f"# Available Layers Count : {len(free_layers) + len(used_layers)}")

            # Check if count of channels required to load sound is available or not
            # Available count of channels : used layers by current channel (will get replaced) + free layers
            if (len(free_layers) + len(used_layers)) < len(source_channels):
                logging.debug(f"{len(source_channels) - len(free_layers) - len(used_layers)} more free channels are required to load sound. Please remove some sound from channels to continue.")
            else:
                # Required free channel count condition satisfied. Continue loading.

                # A counter to keep channel of numner of callbacks called
                # so that post_removal_task can be executed after all callbacks are called
                cb_counter = 0

                def post_removal_task():
                    nonlocal cb_counter
                    cb_counter -= 1

                    # Check if all callbacks are called
                    # If all callbacks are called then continue with post_removal_task
                    # Otherwise return
                    if cb_counter > 0:
                        return
                    else:
                        # Repopulate after removing current channel layers
                        free_layers = channel.getFreeLayers()

                        # New channels map's both key and value should be string
                        # That is how load_layer_from_file method expects the values
                        new_channels_map = {}

                        logging.debug(f"### After Removing")
                        logging.debug(f"# Source Channels        : {source_channels}")
                        logging.debug(f"# Free Layers            : {free_layers}")
                        logging.debug(f"# Chained Sounds         : {channel.chainedSounds}")

                        for index, channel in enumerate(source_channels):
                            new_channels_map[f"{channel}"] = f"{free_layers[index]}"

                        logging.debug(f"# Channel map for loading sound : {new_channels_map}")

                        # Populate new chained sounds and update channel
                        new_chained_sounds = []

                        for key, val in new_channels_map.items():
                            new_chained_sounds.append(int(val))

                        if len(new_chained_sounds) < 5:
                            for i in range(5 - len(new_chained_sounds)):
                                new_chained_sounds.append(-1)

                        self.zyngui.currentTaskMessage = f"Loading selected sounds in channel `{channel.name}`"
                        self.zyngui.layer.load_layer_from_file(filepath, new_channels_map)

                        channel.chainedSounds = new_chained_sounds

                        # Repopulate after loading sound
                        free_layers = channel.getFreeLayers()

                        logging.debug(f"### After Loading")
                        logging.debug(f"# Free Layers            : {free_layers}")
                        logging.debug(f"# New Chained Sounds     : {new_chained_sounds}")
                        logging.debug(f"# Chained Sounds         : {channel.chainedSounds}")

                if len(used_layers) > 0:
                    # Remove all current sounds from channel
                    for i in used_layers:
                        cb_counter += 1
                        channel.remove_and_unchain_sound(i, post_removal_task)
                else:
                    # If there are no sounds in curent channel, immediately do post removal task
                    post_removal_task()

            self.zyngui.end_long_task()

        self.zyngui.currentTaskMessage = "Loading sound"
        self.zyngui.do_long_task(task)

    @Slot(None, result=str)
    def suggestedSoundFileName(self):
        channel = self.zyngui.zynthiloops.song.channelsModel.getChannel(self.zyngui.session_dashboard.selectedChannel)
        suggested = ""
        try:
            # Get preset name of connectedSound
            layer_name = str(channel.getLayerNameByMidiChannel(channel.connectedSound).split(" > ")[1])

            # All heuristics related to suggested sound file name goes below

            if layer_name.find("/") >= 0:
                # 1. If preset name contains /, then suggested name should be after last occurring /
                suggested = layer_name.split("/").pop()
            else:
                suggested = layer_name
        except: pass

        return suggested

    ### Property soundsModel
    def get_sounds_model(self):
        return self.__sound_category_filter_proxy_model__

    soundsModel = Property(QObject, get_sounds_model, constant=True)
    ### END Property soundsModel
