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

from PySide2.QtCore import QAbstractListModel, QObject, Qt, Property, Signal, Slot
from zynqtgui import zynthian_gui_config
from zynqtgui.zynthiloops.libzl.zynthiloops_mix import zynthiloops_mix


class zynthiloops_mixes_model(QAbstractListModel):
    MixRole = Qt.UserRole + 1

    def __init__(self, parent=None):
        super().__init__(parent)
        self.zyngui = zynthian_gui_config.zyngui
        self.__song__ = self.zyngui.zynthiloops.song
        self.__selected_mix_index = 0
        self.__mixes: dict[int, zynthiloops_mix] = {}

    def serialize(self):
        logging.debug("### Serializing Mixes Model")

        return {
            "selectedMixIndex": self.__selected_mix_index,
            "mixes": [self.__mixes[mix_index].serialize() for mix_index in self.__mixes],
        }

    def deserialize(self, obj):
        logging.debug("### Deserializing Mixes Model")

        if "selectedMixIndex" in obj:
            self.set_selectedMixIndex(obj["selectedMixIndex"], True)
        if "mixes" in obj:
            self.beginResetModel()
            self.__mixes.clear()

            for mix_obj in obj["mixes"]:
                mix = zynthiloops_mix(-1, self)
                mix.deserialize(mix_obj)

                self.add_mix(mix.mixId, mix)

            self.endResetModel()

    def data(self, index, role=None):
        if not index.isValid():
            return None

        if index.row() > len(self.__mixes):
            return None

        if role == self.MixRole:
            return self.__mixes[index.row()]
        else:
            return None

    def roleNames(self):
        role_names = {
            Qt.DisplayRole: b'display',
            self.MixRole: b"mix",
        }

        return role_names

    def rowCount(self, index):
        return self.get_count()

    def add_mix(self, mix_index, mix: zynthiloops_mix):
        self.__mixes[mix_index] = mix

    ### Property count
    def get_count(self):
        return len(self.__mixes)

    countChanged = Signal()

    count = Property(int, get_count, notify=countChanged)
    ### END Property count

    ### Property selectedMixIndex
    def get_selectedMixIndex(self):
        return self.__selected_mix_index

    def set_selectedMixIndex(self, index, force_set=False):
        if self.__selected_mix_index != index or force_set:
            self.__selected_mix_index = index
            self.selectedMixIndexChanged.emit()

    selectedMixIndexChanged = Signal()

    selectedMixIndex = Property(int, get_selectedMixIndex, set_selectedMixIndex, notify=selectedMixIndexChanged)
    ### END Property selectedMixIndex

    @Slot(int, result=QObject)
    def getMix(self, mix_index):
        try:
            return self.__mixes[mix_index]
        except:
            return None
