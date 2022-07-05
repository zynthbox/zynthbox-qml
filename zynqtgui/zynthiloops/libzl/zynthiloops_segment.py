#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthiloops Part: An object to store segment
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

from PySide2.QtCore import Property, QObject, Signal
from ... import zynthian_gui_config


class zynthiloops_segment(QObject):
    def __init__(self, mix_id, segment_id, parent=None):
        super().__init__(parent)
        self.zyngui = zynthian_gui_config.zyngui
        self.__song = self.zyngui.zynthiloops.song

        self.__segment_id = segment_id
        self.__mix_id = mix_id

    def serialize(self):
        logging.debug("### Serializing Segment")

        return {
            "mixId": self.__mix_id,
            "segmentId": self.__segment_id,
        }

    def deserialize(self, obj):
        logging.debug("### Deserializing Segment")

        if "mixId" in obj:
            self.set_mixId(obj["mixId"], True)
        if "segmentId" in obj:
            self.set_segmentId(obj["segmentId"], True)

    ### Property name
    def get_name(self):
        return f"Segment {self.__segment_id + 1}"

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

    ### Property segmentId
    def get_segmentId(self):
        return self.__segment_id

    def set_segmentId(self, segment_id, force_set=False):
        if self.__segment_id != segment_id or force_set:
            self.__segment_id = segment_id
            self.segmentIdChanged.emit()

    segmentIdChanged = Signal()

    segmentId = Property(int, get_segmentId, notify=segmentIdChanged)
    ### END Property segmentId

    ### Property name
    def get_name(self):
        return f"Segment {self.__segment_id + 1}"

    name = Property(str, get_name, constant=True)
    ### END Property name

    ### Property isEmpty
    def get_isEmpty(self):
        return True

    isEmptyChanged = Signal()

    isEmpty = Property(bool, get_isEmpty, notify=isEmptyChanged)
    ### END Property isEmpty
