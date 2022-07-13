#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to store mixes of a song in ZynthiLoops
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

from PySide2.QtCore import QAbstractListModel, QObject, Qt, QTimer, Property, Signal, Slot
from zynqtgui import zynthian_gui_config
from zynqtgui.zynthiloops.libzl.zynthiloops_segment import zynthiloops_segment


class zynthiloops_segments_model(QAbstractListModel):
    SegmentRole = Qt.UserRole + 1

    def __init__(self, song, mix):
        super().__init__(song)
        self.zyngui = zynthian_gui_config.zyngui

        self.__song = song
        self.__mix = mix
        self.__selected_segment_index = 0
        self.__segments: dict[int, zynthiloops_segment] = {}
        self.totalBeatDurationThrottle = QTimer()
        self.totalBeatDurationThrottle.setInterval(1)
        self.totalBeatDurationThrottle.setSingleShot(True)
        self.totalBeatDurationThrottle.timeout.connect(self.totalBeatDurationChanged.emit)

    def serialize(self):
        logging.debug("### Serializing Segments Model")

        return [self.__segments[segment_index].serialize() for segment_index in self.__segments]

    def deserialize(self, obj):
        logging.debug("### Deserializing Segments Model")

        self.beginResetModel()
        self.__segments.clear()

        for index, segment_obj in enumerate(obj):
            segment = zynthiloops_segment(self.__mix, -1, self.__song)
            segment.deserialize(segment_obj)

            self.add_segment(segment.segmentId, segment)

        self.endResetModel()

    def data(self, index, role=None):
        if not index.isValid():
            return None

        if index.row() > len(self.__segments):
            return None

        if role == self.SegmentRole:
            return self.__segments[index.row()]
        else:
            return None

    def roleNames(self):
        role_names = {
            Qt.DisplayRole: b'display',
            self.SegmentRole: b"segment",
        }

        return role_names

    def rowCount(self, index):
        return self.get_count()

    def add_segment(self, segment_index, segment: zynthiloops_segment):
        self.__segments[segment_index] = segment
        segment.barLengthChanged.connect(self.totalBeatDurationThrottle.start)
        segment.beatLengthChanged.connect(self.totalBeatDurationThrottle.start)
        self.totalBeatDurationThrottle.start()

    ### Property count
    def get_count(self):
        return len(self.__segments)

    countChanged = Signal()

    count = Property(int, get_count, notify=countChanged)
    ### END Property count

    ### Property totalBeatDuration
    def get_totalBeatDuration(self):
        totalDuration = 0
        for segmentIndex in self.__segments:
            segment = self.__segments[segmentIndex]
            totalDuration += segment.barLength * 4 + segment.beatLength
        return totalDuration

    totalBeatDurationChanged = Signal()

    totalBeatDuration = Property(int, get_totalBeatDuration, notify=totalBeatDurationChanged)
    ### END Property totalBeatDuration

    ### Property selectedSegmentIndex
    def get_selectedSegmentIndex(self):
        return self.__selected_segment_index

    def set_selectedSegmentIndex(self, index):
        if self.__selected_segment_index != index:
            self.__selected_segment_index = index
            self.selectedSegmentIndexChanged.emit()

    selectedSegmentIndexChanged = Signal()

    selectedSegmentIndex = Property(int, get_selectedSegmentIndex, set_selectedSegmentIndex,
                                    notify=selectedSegmentIndexChanged)
    ### END Property selectedSegmentIndex

    ### Property selectedSegment
    def get_selectedSegment(self):
        return self.__segments[self.__selected_segment_index]

    selectedSegment = Property(QObject, get_selectedSegment, notify=selectedSegmentIndexChanged)
    ### END Property selectedSegment

    @Slot(int, result=QObject)
    def get_segment(self, segment_index):
        try:
            return self.__segments[segment_index]
        except:
            return None

    @Slot(QObject)
    def copyFrom(self, dest_segments_model):
        for segment_index in range(self.count):
            self.get_segment(segment_index).copyFrom(dest_segments_model.get_segment(segment_index))

    @Slot()
    def clear(self):
        for segment_index in range(self.count):
            self.get_segment(segment_index).clear()