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
import json
import Zynthbox
from json import JSONEncoder
from pathlib import Path

from PySide2.QtCore import Property, QObject, QSortFilterProxyModel, Qt, Slot

from .sound_categories_sounds_model import sound_categories_sounds_model
from .zynthbox_sound import zynthbox_sound
from .. import zynthian_qt_gui_base


class zynthian_gui_sound_categories(zynthian_qt_gui_base.zynqtgui):
    def __init__(self, parent=None):
        super(zynthian_gui_sound_categories, self).__init__(parent)
        self.__sounds_base_path__ = Path('/zynthian/zynthian-my-data/sounds')
        self.__community_sounds_path__ = self.__sounds_base_path__ / 'community-sounds'
        self.__my_sounds_path__ = self.__sounds_base_path__ / 'my-sounds'
        self.__sound_category_name_mapping__ = {
            "*": "All",
            "0": "Uncategorized",
            "1": "Drums",
            "2": "Bass",
            "3": "Leads",
            "4": "Synth/Keys",
            "5": "Strings/Pads",
            "6": "Guitar/Plucks",
            "99": "FX/Other",
        }

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

    # # Returns the category index if found otherwise returns 0 for uncategorized entries
    # @staticmethod
    # def get_category_for_sound(sound_file):
    #     category = "0"

    #     with open(sound_file, "r") as file:
    #         sound_json = json.load(file)
    #         try:
    #             category = sound_json["category"]
    #         except: pass

    #     return category

    @Slot(str, result=str)
    def getCategoryNameFromKey(self, key):
        try:
            return self.__sound_category_name_mapping__[key]
        except Exception as e:
            logging.debug(f"Sound Category with key `{key}` not found : {str(e)}")
            return ""

    @Slot(str, result=bool)
    def checkIfSoundFileExists(self, filename):
        return len(list(self.__my_sounds_path__.glob(f"**/{filename}.snd"))) > 0

    @Slot(str, int, result=QObject)
    def saveSound(self, name: str, category: int):
        if not name.endswith(".snd"):
            name = f"{name}.snd"
        selectedTrack = self.zynqtgui.sketchpad.song.channelsModel.getChannel(self.zynqtgui.sketchpad.selectedTrackId)
        sound = zynthbox_sound(self, self.zynqtgui, name, "my-sounds")
        sound.metadata.synthFxSnapshot = selectedTrack.getChannelSoundSnapshot()
        sound.metadata.sampleSnapshot = selectedTrack.getChannelSampleSnapshot()
        sound.metadata.category = category
        sound.metadata.write()
        # self.__sounds_model__.add_sound(sound)

    @Slot(QObject)
    def loadSound(self, sound: zynthbox_sound):
        def confirmLoadSound(params=None):
            selectedTrack = self.zynqtgui.sketchpad.song.channelsModel.getChannel(self.zynqtgui.sketchpad.selectedTrackId)
            selectedTrack.setChannelSoundFromSnapshot(sound.metadata.synthFxSnapshot)
            selectedTrack.setChannelSamplesFromSnapshot(sound.metadata.sampleSnapshot)
        self.zynqtgui.show_confirm("Loading sound will replace all synth, samples and fx in track. Do you really want to continue?", confirmLoadSound)

    @Slot(None, result=str)
    def suggestedSoundFileName(self):
        channel = self.zynqtgui.sketchpad.song.channelsModel.getChannel(self.zynqtgui.sketchpad.selectedTrackId)
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

    @Slot()
    def generateStatFiles(self):
        def task():
            Zynthbox.SndLibrary.instance().serializeTo("/zynthian/zynthian-my-data/sounds/my-sounds", "/zynthian/zynthian-my-data/sounds/my-sounds/.stat.json")
            Zynthbox.SndLibrary.instance().serializeTo("/zynthian/zynthian-my-data/sounds/community-sounds", "/zynthian/zynthian-my-data/sounds/community-sounds/.stat.json")
            # Refresh the models after generating stats files to update the UI
            Zynthbox.SndLibrary.instance().refresh()
            self.zynqtgui.end_long_task()
        self.zynqtgui.do_long_task(task, "Generating sound statistics")
