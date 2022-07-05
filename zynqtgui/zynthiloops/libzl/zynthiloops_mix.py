#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthiloops Part: An object to store mix
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

from .zynthiloops_segments_model import zynthiloops_segments_model
from ... import zynthian_gui_config


class zynthiloops_mix(QObject):
    def __init__(self, mix_id, parent=None):
        super().__init__(parent)
        self.zyngui = zynthian_gui_config.zyngui
        self.__song = self.zyngui.zynthiloops.song

        self.__mix_id = mix_id
        self.__segments_model = zynthiloops_segments_model(self)

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