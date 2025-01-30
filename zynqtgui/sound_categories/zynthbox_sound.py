#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Create and manipulate zynthbox sound wav files
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
from pathlib import Path

from PySide2.QtCore import Qt, Property, QObject, Signal, QTimer, QMetaObject


class zynthbox_sound_metadata(QObject):
    def __init__(self, sound):
        super(zynthbox_sound_metadata, self).__init__(sound)

        self.sound = sound
        self.__wavMetadata = None

        # Sound metadata
        self.__synthFxSnapshot = None
        self.__samples = None
        self.__category = None

    def get_synthFxSnapshot(self): return self.__synthFxSnapshot
    def get_samples(self): return self.__samples
    def get_category(self): return self.__category

    def set_synthFxSnapshot(self, value, force=False):
        if value != self.__synthFxSnapshot or force:
            self.__synthFxSnapshot = value
            self.synthFxSnapshotChanged.emit()
    def set_samples(self, value, force=False):
        if value != self.__samples or force:
            self.__samples = value
            self.samplesChanged.emit()
    def set_category(self, value, force=False):
        if value != self.__category or force:
            self.__category = value
            self.categoryChanged.emit()

    synthFxSnapshotChanged = Signal()
    samplesChanged = Signal()
    categoryChanged = Signal()

    synthFxSnapshot = Property(str, get_synthFxSnapshot, set_synthFxSnapshot, notify=synthFxSnapshotChanged)
    samples = Property(str, get_samples, set_samples, notify=samplesChanged)
    # Valid category values
    # 0 : Uncategorized
    # 1: Drums
    # 2: Bass
    # 3: Leads
    # 4: Keys/Pads
    # 99: Other
    category = Property(int, get_category, set_category, notify=categoryChanged)

    def getMetadataProperty(self, name, default=None):
        try:
            value = self.__wavMetadata[name][0]
            if value == "None":
                # If 'None' value is saved, return default
                return default
            return value
        except:
            return default

    def read(self, load_autosave=True):
        if self.sound.exists():
            try:
                file = taglib.File(self.sound.path)
                logging.debug(f"Reading sound metadata for {self.sound} : {self.sound.path}")
                self.__wavMetadata = file.tags
                file.close()
            except Exception as e:
                self.__wavMetadata = None
                logging.error(f"Error reading metadata from sound {self.sound.path} : {str(e)}")

            # TODO Probably have some fault safety here, in case there's bunk metadata?
            self.set_synthFxSnapshot(str(self.getMetadataProperty("ZYNTHBOX_SOUND_SYNTH_FX_SNAPSHOT", None)), force=True)
            self.set_samples(str(self.getMetadataProperty("ZYNTHBOX_SOUND_SAMPLES", None)), force=True)
            self.set_category(int(self.getMetadataProperty("ZYNTHBOX_SOUND_CATEGORY", 0)), force=True)

    def write(self):
        if self.sound.exists():
            tags = {}
            tags["ZYNTHBOX_SOUND_SYNTH_FX_SNAPSHOT"] = [str(self.__synthFxSnapshot)]
            tags["ZYNTHBOX_SOUND_SAMPLES"] = [str(self.__samples)]
            tags["ZYNTHBOX_SOUND_CATEGORY"] = [str(self.__category)]
            try:
                file = taglib.File(self.sound.path)
                logging.debug(f"Writing sound metadata {self.sound} : {self.sound.path}")
                for key, value in tags.items():
                    file.tags[key] = value
                file.save()
            except Exception as e:
                logging.exception(f"Error writing metadata : {str(e)}")

    def clear(self):
        self.set_synthFxSnapshot(None, write=False, force=True)
        self.set_samples(None, write=False, force=True)
        self.set_category(None, write=False, force=True)


class zynthbox_sound(QObject):
    def __init__(self, parent, zynqtgui, name, type):
        super().__init__(parent)
        self.__sounds_base_path = Path('/zynthian/zynthian-my-data/sounds')

        self.zynqtgui = zynqtgui
        self.__name = name
        self.__type = type
        self.__sound_file = self.__sounds_base_path / type / self.__name

        # Create empty sound file if not exists
        if not self.__sound_file.exists():
            subprocess.run(shlex.split(f"ffmpeg -f lavfi -t 0 -i anullsrc=channel_layout=stereo:sample_rate=48000:d=0 -y {str(self.__sound_file)}"))

        self.__metadata = zynthbox_sound_metadata(self)
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
