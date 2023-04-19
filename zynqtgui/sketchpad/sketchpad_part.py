#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Sketchpad Part: An object to store clips of a part
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
from .sketchpad_clip import sketchpad_clip

class sketchpad_part(QObject):
    def __init__(self, part_index: int, song,  parent=None):
        super(sketchpad_part, self).__init__(parent)
        self.__part_index__ = part_index
        self.__clips__ = []
        self.__is_playing__ = False
        self.__length__ = 1
        self.__song__ = song
        # self.__name__ = chr(self.__part_index__+65) # A B C ...

        if self.__part_index__ == 0:
            self.__name__ = "I"
        elif self.__part_index__ == 1:
            self.__name__ = "II"
        else:
            self.__name__ = ""

    def serialize(self):
        return {"name": self.__name__,
                "length": self.__length__}

    def deserialize(self, obj):
        if "name" in obj:
            self.__name__ = obj["name"]
        if "length" in obj:
            self.__length__ = obj["length"]

    def playable(self):
        return True
    playable = Property(bool, playable, constant=True)

    def recordable(self):
        return False
    recordable = Property(bool, recordable, constant=True)

    def clearable(self):
        return True
    clearable = Property(bool, clearable, constant=True)

    def deletable(self):
        return True
    deletable = Property(bool, deletable, constant=True)

    def nameEditable(self):
        return True
    nameEditable = Property(bool, nameEditable, constant=True)

    @Signal
    def __is_playing_changed__(self):
        pass

    def isPlaying(self):
        return self.__is_playing__

    def __set_is_playing__(self, is_playing: bool):
        self.__is_playing__ = is_playing
        self.__is_playing_changed__.emit()

    isPlaying = Property(bool, isPlaying, __set_is_playing__, notify=__is_playing_changed__)

    @Signal
    def length_changed(self):
        pass

    @Signal
    def part_index_changed(self):
        pass

    @Signal
    def name_changed(self):
        pass

    def length(self):
        return self.__length__

    def set_length(self, length: int):
        self.__length__ = length
        self.length_changed.emit()
        self.__song__.schedule_save()
    length = Property(int, length, set_length, notify=length_changed)


    def partIndex(self):
        return self.__part_index__

    def set_part_index(self, part_index):
        self.__part_index__ = part_index
        self.part_index_changed.emit()

    partIndex = Property(int, partIndex, set_part_index, notify=part_index_changed)



    def name(self):
        return self.__name__

    def set_name(self, name):
        self.__name__ = name
        self.name_changed.emit()
        self.__song__.schedule_save()
    name = Property(str, name, set_name, notify=name_changed)

    @Slot(None)
    def clear(self):
        for i in range(0, self.__song__.channelsModel.count):
            channel = self.__song__.channelsModel.getChannel(i)
            clipsModel = channel.clipsModel
            logging.debug(f"Channel {channel} ClipsModel {clipsModel}")

            for clip_index in range(0, clipsModel.count):
                logging.debug(f"Channel {i} Clip {clip_index}")
                clip: sketchpad_clip = clipsModel.getClip(clip_index)

                if clip.col == self.partIndex:
                    logging.debug(
                        f"Clip : clip.row({clip.row}), clip.col({clip.col}), self.partIndex({self.partIndex}),  clip({clip})")
                    clip.clear()

    @Slot(None)
    def play(self):
        logging.info(f"Playing Part {self.partIndex}")

        # for i in range(0, self.__song__.partsModel.count):
        #     part = self.__song__.partsModel.getPart(i)
        #     part.stop()

        for i in range(0, self.__song__.channelsModel.count):
            channel = self.__song__.channelsModel.getChannel(i)
            clipsModel = channel.clipsModel
            logging.debug(f"Channel {channel} ClipsModel {clipsModel}")

            for clip_index in range(0, clipsModel.count):
                logging.debug(f"Channel {i} Clip {clip_index}")
                clip: sketchpad_clip = clipsModel.getClip(clip_index)

                if clip.col == self.partIndex:
                    logging.debug(f"Clip : clip.row({clip.row}), clip.col({clip.col}), self.partIndex({self.partIndex}),  clip({clip})")
                    clip.play()

        self.__is_playing__ = True
        self.__is_playing_changed__.emit()

    @Slot(None)
    def stop(self):
        for i in range(0, self.__song__.channelsModel.count):
            clipsModel = self.__song__.channelsModel.getChannel(i).clipsModel

            for clip_index in range(0, clipsModel.count):
                clip: sketchpad_clip = clipsModel.getClip(clip_index)

                if clip.col == self.partIndex:
                    logging.debug(f"Stopping clip : clip.row({clip.row}), clip.col({clip.col}), self.partIndex({self.partIndex}),  clip({clip})")
                    clip.stop()

        self.__is_playing__ = False
        self.__is_playing_changed__.emit()
