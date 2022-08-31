#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Sketchpad Part: An object to store mix
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

from .sketchpad_segments_model import sketchpad_segments_model
from zynqtgui import zynthian_gui_config


class sketchpad_mix(QObject):
    def __init__(self, mix_id, song):
        super().__init__(song)
        self.zyngui = zynthian_gui_config.zyngui

        self.__song = song
        self.__mix_id = mix_id
        self.__segments_model = sketchpad_segments_model(song, self)
        self.__is_empty = True

    def serialize(self):
        logging.debug("### Serializing Mix")

        return {
            "mixId": self.__mix_id,
            "segments": self.__segments_model.serialize(),
        }

    def deserialize(self, obj):
        logging.debug("### Deserializing Mix")

        if "mixId" in obj:
            self.set_mixId(obj["mixId"], True)
        if "segments" in obj:
            self.__segments_model.deserialize(obj["segments"])

    ### Property className
    def get_className(self):
        return "sketchpad_mix"

    className = Property(str, get_className, constant=True)
    ### END Property className

    ### Property name
    def get_name(self):
        return f"Mix {self.__mix_id + 1}"

    name = Property(str, get_name, constant=True)
    ### END Property name

    ### Property mixId
    def get_mixId(self):
        return self.__mix_id

    def set_mixId(self, mix_id, force_set=False):
        if self.__mix_id != mix_id or force_set:
            self.__mix_id = mix_id
            self.mixIdChanged.emit()

    mixIdChanged = Signal()

    mixId = Property(int, get_mixId, notify=mixIdChanged)
    ### END Property mixId

    ### Property segmentsModel
    def get_segmentsModel(self):
        return self.__segments_model

    segmentsModelChanged = Signal()

    segmentsModel = Property(QObject, get_segmentsModel, notify=segmentsModelChanged)
    ### END Property segmentsModel

    ### Property isEmpty
    def get_isEmpty(self):
        return self.__is_empty

    def set_isEmpty(self, val):
        if self.__is_empty != val:
            self.__is_empty = val
            self.isEmptyChanged.emit()

    isEmptyChanged = Signal()

    isEmpty = Property(bool, get_isEmpty, notify=isEmptyChanged)
    ### END Property isEmpty

    @Slot(int, result=QObject)
    def getSegment(self, segmentIndex):
        return self.segmentsModel.get_segment(segmentIndex)

    @Slot()
    def segment_is_empty_changed_handler(self):
        is_empty = True
        for segment_index in range(self.segmentsModel.count):
            segment = self.segmentsModel.get_segment(segment_index)
            if not segment.isEmpty:
                is_empty = False
                break

        self.set_isEmpty(is_empty)

    @Slot(QObject)
    def copyFrom(self, dest_mix):
        self.segmentsModel.copyFrom(dest_mix.segmentsModel)

    @Slot()
    def clear(self):
        self.segmentsModel.clear()
