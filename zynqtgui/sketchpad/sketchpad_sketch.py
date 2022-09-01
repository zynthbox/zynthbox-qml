#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Sketchpad Part: An object to store sketch
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


class sketchpad_sketch(QObject):
    def __init__(self, sketch_id, song):
        super().__init__(song)
        self.zyngui = zynthian_gui_config.zyngui

        self.__song = song
        self.__sketch_id = sketch_id
        self.__segments_model = sketchpad_segments_model(song, self)
        self.__is_empty = True

    def serialize(self):
        logging.debug("### Serializing Sketch")

        return {
            "sketchId": self.__sketch_id,
            "segments": self.__segments_model.serialize(),
        }

    def deserialize(self, obj):
        logging.debug("### Deserializing Sketch")

        if "sketchId" in obj:
            self.set_sketchId(obj["sketchId"], True)
        if "segments" in obj:
            self.__segments_model.deserialize(obj["segments"])

    ### Property className
    def get_className(self):
        return "sketchpad_sketch"

    className = Property(str, get_className, constant=True)
    ### END Property className

    ### Property name
    def get_name(self):
        return f"Sketch {self.__sketch_id + 1}"

    name = Property(str, get_name, constant=True)
    ### END Property name

    ### Property sketchId
    def get_sketchId(self):
        return self.__sketch_id

    def set_sketchId(self, sketch_id, force_set=False):
        if self.__sketch_id != sketch_id or force_set:
            self.__sketch_id = sketch_id
            self.sketchIdChanged.emit()

    sketchIdChanged = Signal()

    sketchId = Property(int, get_sketchId, notify=sketchIdChanged)
    ### END Property sketchId

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
    def copyFrom(self, dest_sketch):
        self.segmentsModel.copyFrom(dest_sketch.segmentsModel)

    @Slot()
    def clear(self):
        self.segmentsModel.clear()
