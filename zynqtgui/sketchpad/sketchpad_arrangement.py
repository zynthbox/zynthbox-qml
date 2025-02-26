#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Sketchpad Arrangement: An object to store a song arrangement (essentially, a list of segments)
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


class sketchpad_arrangement(QObject):
    def __init__(self, arrangement_id, song):
        super().__init__(song)
        self.zynqtgui = zynthian_gui_config.zynqtgui

        self.__song = song
        self.__arrangement_id = arrangement_id
        self.__segments_models = [sketchpad_segments_model(song, self)]
        self.__segments_model = 0
        self.__is_empty = True

    def serialize(self):
        logging.debug("### Serializing Arrangement")

        segmentsData = []
        for segmentsModel in self.__segments_models:
            segmentsData.append(segmentsModel.serialize())
        return {
            "arrangementId": self.__arrangement_id,
            "segments": segmentsData,
        }

    def deserialize(self, obj):
        logging.debug("### Deserializing Arrangement")

        self.__segments_models = []
        if "sketchId" in obj:
            self.set_arrangementId(obj["sketchId"], True)
        if "arrangementId" in obj:
            self.set_arrangementId(obj["arrangementId"], True)
        if "segments" in obj:
            if "barLength" in obj["segments"]:
                # In this case, we've got an old single segment sitting around - we can get rid of this bit in a little bit
                self.__segments_models.append(sketchpad_segments_model(self.__song, self))
                self.__segments_models[0].deserialize(obj["segments"])
            else:
                for segmentData in obj["segments"]:
                    segmentModel = sketchpad_segments_model(self.__song, self)
                    segmentModel.deserialize(segmentData)
                    self.__segments_models.append(segmentModel)
        self.__segments_model = 0
        if len(self.__segments_models) == 0:
            self.__segments_models.append(sketchpad_segments_model(self.__song, self))
        if self.__segments_models[0].count == 0:
            newSegment = self.__segments_models[0].new_segment()
            newSegment.barLength = 1
        self.segmentsModelChanged.emit()
        self.segmentsModelsCountChanged.emit()

    ### Property className
    def get_className(self):
        return "sketchpad_arrangement"

    className = Property(str, get_className, constant=True)
    ### END Property className

    ### Property name
    def get_name(self):
        return f"Arrangement {self.__sketch_id + 1}"

    name = Property(str, get_name, constant=True)
    ### END Property name

    ### Property arrangementId
    def get_arrangementId(self):
        return self.__arrangement_id

    def set_arrangementId(self, arrangement_id, force_set=False):
        if self.__arrangement_id != arrangement_id or force_set:
            self.__arrangement_id = arrangement_id
            self.arrangementIdChanged.emit()

    arrangementIdChanged = Signal()

    arrangementId = Property(int, get_arrangementId, notify=arrangementIdChanged)
    ### END Property arrangementId

    @Slot(None, result=int)
    def newSegmentsModel(self):
        newIndex = len(self.__segments_models)
        newSegmentsModel = sketchpad_segments_model(self.__song, self)
        newSegment = newSegmentsModel.new_segment()
        newSegment.barLength = 1
        self.__segments_models.append(newSegmentsModel)
        self.segmentsModelsCountChanged.emit()
        return newIndex

    @Slot(int)
    def removeSegmentsModel(self, index):
        if index > -1 and index < len(self.__segments_models):
            self.__segments_models.pop(index)
            if len(self.__segments_models) == 0:
                self.newSegmentsModel()
            self.segmentsModelChanged.emit()
            self.segmentsModelsCountChanged.emit()

    @Slot(int, result=int)
    def cloneSegmentAsNew(self, index):
        if index > -1 and index < len(self.__segments_models):
            newIndex = len(self.__segments_models)
            newModel = sketchpad_segments_model(self.__song, self)
            self.__segments_models.append(newModel)
            newModel.copyFrom(self.__segments_models[index])
            self.segmentsModelsCountChanged.emit()
            return newIndex
        return -1

    ### Property segmentsModelsCount
    def get_segmentsModelsCount(self):
        return len(self.__segments_models)

    segmentsModelsCountChanged = Signal()

    segmentsModelsCount = Property(int, get_segmentsModelsCount, notify=segmentsModelsCountChanged)
    ### END segmentsModelsCount

    segmentsModelChanged = Signal()

    ### Property segmentsModelIndex
    def get_segmentsModelIndex(self):
        return self.__segments_model

    def set_segmentsModelIndex(self, value):
        if self.__segments_model != value and value > -1 and value < len(self.__segments_models):
            self.__segments_model = value
            self.segmentsModelChanged.emit()

    segmentsModelIndex = Property(int, get_segmentsModelIndex, set_segmentsModelIndex, notify=segmentsModelChanged)
    ### END Property segmentsModelIndex

    @Slot(int, result=QObject)
    def getSegmentsModel(self, index):
        if index > -1 and index < len(self.__segments_models):
            return self.__segments_models[index]
        return None

    ### Property segmentsModel
    def get_segmentsModel(self):
        if self.__segments_model > -1 and self.__segments_model < len(self.__segments_models):
            return self.__segments_models[self.__segments_model]
        return None

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
    def copyFrom(self, dest_arrangement):
        self.segmentsModel.copyFrom(dest_arrangement.segmentsModel)

    @Slot()
    def clear(self):
        self.segmentsModel.clear()
