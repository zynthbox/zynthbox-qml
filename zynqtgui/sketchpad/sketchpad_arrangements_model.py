#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to store arrangements of a song in Sketchpad
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
from zynqtgui.sketchpad.sketchpad_arrangement import sketchpad_arrangement


class sketchpad_arrangements_model(QAbstractListModel):
    ArrangementRole = Qt.UserRole + 1

    def __init__(self, song):
        super().__init__(song)
        self.zynqtgui = zynthian_gui_config.zynqtgui

        self.__song = song
        self.__selected_arrangement_index = 0
        self.__arrangements: dict[int, sketchpad_arrangement] = {}

    def serialize(self):
        logging.debug("### Serializing Arrangements Model")

        return {
            "selectedArrangementIndex": self.__selected_arrangement_index,
            "arrangements": [self.__arrangements[arrangement_index].serialize() for arrangement_index in self.__arrangements],
        }

    def deserialize(self, obj):
        logging.debug("### Deserializing Arrangements Model")

        # TODO Remove this when we're sure there's nothing more left
        if "selectedSketchIndex" in obj:
            self.set_selectedArrangementIndex(obj["selectedSketchIndex"], True)
        if "sketches" in obj:
            self.beginResetModel()
            self.__arrangements.clear()

            for arrangement_obj in obj["sketches"]:
                arrangement = sketchpad_arrangement(-1, self.__song)
                arrangement.deserialize(arrangement_obj)

                self.add_arrangement(arrangement.arrangementId, arrangement)

            self.endResetModel()
        if "selectedArrangementIndex" in obj:
            self.set_selectedArrangementIndex(obj["selectedArrangementIndex"], True)
        if "arrangements" in obj:
            self.beginResetModel()
            self.__arrangements.clear()

            for arrangement_obj in obj["arrangements"]:
                arrangement = sketchpad_arrangement(-1, self.__song)
                arrangement.deserialize(arrangement_obj)

                self.add_arrangement(arrangement.arrangementId, arrangement)

            self.endResetModel()

    def data(self, index, role=None):
        if not index.isValid():
            return None

        if index.row() > len(self.__sketches):
            return None

        if role == self.ArrangementRole:
            return self.__arrangements[index.row()]
        else:
            return None

    def roleNames(self):
        role_names = {
            Qt.DisplayRole: b'display',
            self.ArrangementRole: b"arrangement",
        }

        return role_names

    def rowCount(self, index):
        return self.get_count()

    def add_arrangement(self, arrangement_index, arrangement: sketchpad_arrangement):
        self.__arrangements[arrangement_index] = arrangement

    ### Property count
    def get_count(self):
        return len(self.__arrangements)

    countChanged = Signal()

    count = Property(int, get_count, notify=countChanged)
    ### END Property count

    ### Property selectedArrangementIndex
    def get_selectedArrangementIndex(self):
        return self.__selected_arrangement_index

    def set_selectedArrangementIndex(self, index, force_set=False):
        if self.__selected_arrangement_index != index or force_set:
            self.__selected_arrangement_index = index
            self.selectedArrangementIndexChanged.emit()

    selectedArrangementIndexChanged = Signal()

    selectedArrangementIndex = Property(int, get_selectedArrangementIndex, set_selectedArrangementIndex, notify=selectedArrangementIndexChanged)
    ### END Property selectedArrangementIndex

    ### Property selectedArrangement
    def get_selectedArrangement(self):
        return self.__arrangements[self.__selected_arrangement_index]

    selectedArrangement = Property(QObject, get_selectedArrangement, notify=selectedArrangementIndexChanged)
    ### END Property selectedArrangement

    @Slot(int, result=QObject)
    def getArrangement(self, arrangement_index):
        try:
            return self.__arrangements[arrangement_index]
        except:
            return None

    clipAdded = Signal(int, int, QObject)
    clipRemoved = Signal(int, int, QObject)
