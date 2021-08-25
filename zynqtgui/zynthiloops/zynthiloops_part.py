#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthiloops Part: An object to store clips of a part
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

from PySide2.QtCore import Property, QObject, Signal, Slot

from .zynthiloops_clip import zynthiloops_clip
from .. import zynthian_gui_config

class zynthiloops_part(QObject):
    def __init__(self, part_index: int, song,  parent=None):
        super(zynthiloops_part, self).__init__(parent)
        self.zyngui = zynthian_gui_config.zyngui
        self.__part_index__ = part_index
        self.__clips__ = []
        self.__is_playing__ = False
        self.__length__ = 1
        self.__song__ = song
        self.__name__ = chr(self.__part_index__+65) # A B C ...

    def serialize(self):
        return {"name": self.__name__,
                "length": self.__length__}

    def deserialize(self, obj):
        if "name" in obj:
            self.__name__ = obj["name"]
        if "length" in obj:
            self.__length__ = obj["length"]

    @Property(bool, constant=True)
    def playable(self):
        return True

    @Property(bool, constant=True)
    def recordable(self):
        return False

    @Property(bool, constant=True)
    def clearable(self):
        return True

    @Property(bool, constant=True)
    def deletable(self):
        return True

    @Property(bool, constant=True)
    def nameEditable(self):
        return True

    @Signal
    def __is_playing_changed__(self):
        pass

    @Property(bool, notify=__is_playing_changed__)
    def isPlaying(self):
        return self.__is_playing__

    @isPlaying.setter
    def __set_is_playing__(self, is_playing: bool):
        self.__is_playing__ = is_playing
        self.__is_playing_changed__.emit()

    @Signal
    def length_changed(self):
        pass

    @Signal
    def part_index_changed(self):
        pass

    @Signal
    def name_changed(self):
        pass

    @Property(int, notify=length_changed)
    def length(self):
        return self.__length__

    @length.setter
    def set_length(self, length: int):
        self.__length__ = length
        self.length_changed.emit()

    @Property(int, notify=part_index_changed)
    def partIndex(self):
        return self.__part_index__

    @partIndex.setter
    def set_part_index(self, part_index):
        self.__part_index__ = part_index
        self.part_index_changed.emit()

    @Property(str, notify=name_changed)
    def name(self):
        return self.__name__

    @name.setter
    def set_name(self, name):
        self.__name__ = name
        self.name_changed.emit()

    @Slot(None)
    def play(self):
        logging.error(f"Playing Part {self.partIndex}")

        for i in range(0, self.__song__.tracksModel.count):
            track = self.__song__.tracksModel.getTrack(i)
            clipsModel = track.clipsModel
            logging.error(f"Track {track} ClipsModel {clipsModel}")

            for clip_index in range(0, clipsModel.count):
                logging.error(f"Track {i} Clip {clip_index}")
                clip: zynthiloops_clip = clipsModel.getClip(clip_index)

                # if clip.col == self.partIndex:
                logging.error(f"Clip : clip.row({clip.row}), clip.col({clip.col}), self.partIndex({self.partIndex}),  clip({clip})")

        self.__is_playing__ = True
        self.__is_playing_changed__.emit()

    @Slot(None)
    def stop(self):
        for i in range(0, self.__song__.tracksModel.count):
            clipsModel = self.__song__.tracksModel.getTrack(i).clipsModel

            for clip_index in range(0, clipsModel.count):
                clip: zynthiloops_clip = clipsModel.getClip(clip_index)

                if clip.col == self.partIndex:
                    logging.error(f"Stopping clip : clip.row({clip.row}), clip.col({clip.col}), self.partIndex({self.partIndex}),  clip({clip})")

        self.__is_playing__ = False
        self.__is_playing_changed__.emit()
