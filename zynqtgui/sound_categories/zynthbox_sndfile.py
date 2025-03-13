#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Create and manipulate zynthbox .snd files
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
import os
import subprocess
import shlex
import logging
import taglib
import Zynthbox
from pathlib import Path
from PySide2.QtCore import Property, QObject, Signal


class zynthbox_sndfile_metadata(QObject):
    def __init__(self, sound):
        super(zynthbox_sndfile_metadata, self).__init__(sound)

        self.sound = sound
        self.__wavMetadata = None

        # Sound metadata
        self.__synthFxSnapshot = None
        self.__sampleSnapshot = None
        self.__category = None
        self.__synthSlotsData = None
        self.__sampleSlotsData = None
        self.__fxSlotsData = None

    def get_synthFxSnapshot(self): return self.__synthFxSnapshot
    def get_sampleSnapshot(self): return self.__sampleSnapshot
    def get_category(self): return self.__category
    def get_synthSlotsData(self): return self.__synthSlotsData
    def get_sampleSlotsData(self): return self.__sampleSlotsData
    def get_fxSlotsData(self): return self.__fxSlotsData

    def set_synthFxSnapshot(self, value, force=False):
        if value != self.__synthFxSnapshot or force:
            self.__synthFxSnapshot = value
            self.synthFxSnapshotChanged.emit()
    def set_sampleSnapshot(self, value, force=False):
        if value != self.__sampleSnapshot or force:
            self.__sampleSnapshot = value
            self.sampleSnapshotChanged.emit()
    def set_category(self, value, force=False):
        if value != self.__category or force:
            self.__category = value
            self.categoryChanged.emit()
    def set_synthSlotsData(self, value, force=False):
        if value != self.__synthSlotsData or force:
            self.__synthSlotsData = value
            self.synthSlotsDataChanged.emit()
    def set_sampleSlotsData(self, value, force=False):
        if value != self.__sampleSlotsData or force:
            self.__sampleSlotsData = value
            self.sampleSlotsDataChanged.emit()
    def set_fxSlotsData(self, value, force=False):
        if value != self.__fxSlotsData or force:
            self.__fxSlotsData = value
            self.fxSlotsDataChanged.emit()

    synthFxSnapshotChanged = Signal()
    sampleSnapshotChanged = Signal()
    categoryChanged = Signal()
    synthSlotsDataChanged = Signal()
    sampleSlotsDataChanged = Signal()
    fxSlotsDataChanged = Signal()

    synthFxSnapshot = Property(str, get_synthFxSnapshot, set_synthFxSnapshot, notify=synthFxSnapshotChanged)
    sampleSnapshot = Property(str, get_sampleSnapshot, set_sampleSnapshot, notify=sampleSnapshotChanged)
    category = Property(int, get_category, set_category, notify=categoryChanged)
    synthSlotsData = Property(str, get_synthSlotsData, set_synthSlotsData, notify=synthSlotsDataChanged)
    sampleSlotsData = Property(str, get_sampleSlotsData, set_sampleSlotsData, notify=sampleSlotsDataChanged)
    fxSlotsData = Property(str, get_fxSlotsData, set_fxSlotsData, notify=fxSlotsDataChanged)

    def getMetadataProperty(self, name, default=None):
        try:
            # value = self.__wavMetadata[name][0]
            value = self.__wavMetadata[name]
            if value == "None":
                # If 'None' value is saved, return default
                return default
            return value
        except:
            return default

    def read(self, load_autosave=True):
        if self.sound.exists():
            try:
                logging.debug(f"Reading sound metadata for {self.sound} : {self.sound.path}")
                # file = taglib.File(self.sound.path)
                # self.__wavMetadata = file.tags
                # file.close()
                self.__wavMetadata = Zynthbox.AudioTagHelper.instance().readWavMetadata(str(self.sound.path))
            except Exception as e:
                self.__wavMetadata = None
                logging.error(f"Error reading metadata from sound {self.sound.path} : {str(e)}")

            # TODO Probably have some fault safety here, in case there's bunk metadata?
            self.set_synthFxSnapshot(str(self.getMetadataProperty("ZYNTHBOX_SOUND_SYNTH_FX_SNAPSHOT", None)), force=True)
            self.set_sampleSnapshot(str(self.getMetadataProperty("ZYNTHBOX_SOUND_SAMPLE_SNAPSHOT", None)), force=True)
            self.set_category(int(self.getMetadataProperty("ZYNTHBOX_SOUND_CATEGORY", 0)), force=True)
            self.set_synthSlotsData(str(self.getMetadataProperty("ZYNTHBOX_SOUND_SYNTH_SLOTS_DATA", 0)), force=True)
            self.set_sampleSlotsData(str(self.getMetadataProperty("ZYNTHBOX_SOUND_SAMPLE_SLOTS_DATA", 0)), force=True)
            self.set_fxSlotsData(str(self.getMetadataProperty("ZYNTHBOX_SOUND_FX_SLOTS_DATA", 0)), force=True)

    def write(self):
        if self.sound.exists():
            tags = {}
            tags["ZYNTHBOX_SOUND_SYNTH_FX_SNAPSHOT"] = str(self.__synthFxSnapshot)
            tags["ZYNTHBOX_SOUND_SAMPLE_SNAPSHOT"] = str(self.__sampleSnapshot)
            tags["ZYNTHBOX_SOUND_CATEGORY"] = str(self.__category)
            tags["ZYNTHBOX_SOUND_SYNTH_SLOTS_DATA"] = str(self.__synthSlotsData)
            tags["ZYNTHBOX_SOUND_SAMPLE_SLOTS_DATA"] = str(self.__sampleSlotsData)
            tags["ZYNTHBOX_SOUND_FX_SLOTS_DATA"] = str(self.__fxSlotsData)
            try:
                logging.debug(f"Writing sound metadata {self.sound} : {self.sound.path}")
                # file = taglib.File(self.sound.path)
                # for key, value in tags.items():
                #     file.tags[key] = value
                # file.save()
                Zynthbox.AudioTagHelper.instance().saveWavMetadata(str(self.sound.path), tags)
            except Exception as e:
                logging.exception(f"Error writing metadata : {str(e)}")

    def clear(self):
        self.set_synthFxSnapshot(None, write=False, force=True)
        self.set_sampleSnapshot(None, write=False, force=True)
        self.set_category(None, write=False, force=True)
        self.set_synthSlotsData(None, write=False, force=True)
        self.set_sampleSlotsData(None, write=False, force=True)
        self.set_fxSlotsData(None, write=False, force=True)


class zynthbox_sndfile(QObject):
    def __init__(self, parent, zynqtgui, name, type):
        # TODO : Port this class to cpp
        super().__init__(parent)
        self.__sounds_base_path = Path('/zynthian/zynthian-my-data/sounds')

        self.zynqtgui = zynqtgui
        self.__name = name
        self.__type = type
        self.__sound_file = self.__sounds_base_path / type / self.__name

        # Create parent dir if not exists
        self.__sound_file.parent.mkdir(parents=True, exist_ok=True)
        # Create empty sound file if not exists
        if not self.__sound_file.exists():
            subprocess.run(shlex.split(f"ffmpeg -f lavfi -t 0 -i anullsrc=channel_layout=stereo:sample_rate=48000:d=0 -y -f wav {shlex.quote(str(self.__sound_file))}"))

        self.__metadata = zynthbox_sndfile_metadata(self)
        self.__metadata.read()

    def exists(self):
        return Path(self.path).exists()

    ### Property name
    def get_name(self):
        return self.__name

    name = Property(str, get_name, constant=True)
    ### END Property name

    ### Property type
    def get_type(self):
        return self.__type

    type = Property(str, get_type, constant=True)
    ### END Property type

    ### Property path
    def get_path(self):
        if self.__type == "community-sounds":
            return "/zynthian/zynthian-my-data/sounds/community-sounds/"+self.__name
        elif self.__type == "my-sounds":
            return "/zynthian/zynthian-my-data/sounds/my-sounds/"+self.__name
        else:
            return None

    path = Property(str, get_path, constant=True)
    ### END Property path

    ### Property metadata
    def get_metadata(self):
        return self.__metadata

    metadata = Property(QObject, get_metadata, constant=True)
    ### END Property metadata
