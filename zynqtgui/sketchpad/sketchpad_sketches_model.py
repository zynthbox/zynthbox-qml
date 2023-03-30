#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to store sketches of a song in Sketchpad
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
from zynqtgui.sketchpad.sketchpad_sketch import sketchpad_sketch


class sketchpad_sketches_model(QAbstractListModel):
    SketchRole = Qt.UserRole + 1

    def __init__(self, song):
        super().__init__(song)
        self.zynqtgui = zynthian_gui_config.zynqtgui

        self.__song = song
        self.__selected_sketch_index = 0
        self.__sketches: dict[int, sketchpad_sketch] = {}
        self.__song_mode = False

    def serialize(self):
        logging.debug("### Serializing Sketches Model")

        return {
            "selectedSketchIndex": self.__selected_sketch_index,
            "sketches": [self.__sketches[sketch_index].serialize() for sketch_index in self.__sketches],
        }

    def deserialize(self, obj):
        logging.debug("### Deserializing Sketches Model")

        if "selectedSketchIndex" in obj:
            self.set_selectedSketchIndex(obj["selectedSketchIndex"], True)
        if "sketches" in obj:
            self.beginResetModel()
            self.__sketches.clear()

            for sketch_obj in obj["sketches"]:
                sketch = sketchpad_sketch(-1, self.__song)
                sketch.deserialize(sketch_obj)

                self.add_sketch(sketch.sketchId, sketch)

            self.endResetModel()

    def data(self, index, role=None):
        if not index.isValid():
            return None

        if index.row() > len(self.__sketches):
            return None

        if role == self.SketchRole:
            return self.__sketches[index.row()]
        else:
            return None

    def roleNames(self):
        role_names = {
            Qt.DisplayRole: b'display',
            self.SketchRole: b"sketch",
        }

        return role_names

    def rowCount(self, index):
        return self.get_count()

    def add_sketch(self, sketch_index, sketch: sketchpad_sketch):
        self.__sketches[sketch_index] = sketch

    ### Property count
    def get_count(self):
        return len(self.__sketches)

    countChanged = Signal()

    count = Property(int, get_count, notify=countChanged)
    ### END Property count

    ### Property selectedSketchIndex
    def get_selectedSketchIndex(self):
        return self.__selected_sketch_index

    def set_selectedSketchIndex(self, index, force_set=False):
        if self.__selected_sketch_index != index or force_set:
            self.__selected_sketch_index = index
            self.selectedSketchIndexChanged.emit()

    selectedSketchIndexChanged = Signal()

    selectedSketchIndex = Property(int, get_selectedSketchIndex, set_selectedSketchIndex, notify=selectedSketchIndexChanged)
    ### END Property selectedSketchIndex

    ### Property selectedSketch
    def get_selectedSketch(self):
        return self.__sketches[self.__selected_sketch_index]

    selectedSketch = Property(QObject, get_selectedSketch, notify=selectedSketchIndexChanged)
    ### END Property selectedSketch

    ### Property songMode
    def get_songMode(self):
        return self.__song_mode

    def set_songMode(self, value):
        if value != self.__song_mode:
            self.__song_mode = value
            self.songModeChanged.emit()
            self.zynqtgui.sketchpad.set_selector()

    songModeChanged = Signal()

    songMode = Property(bool, get_songMode, set_songMode, notify=songModeChanged)
    ### END Property songMode

    @Slot(int, result=QObject)
    def getSketch(self, sketch_index):
        try:
            return self.__sketches[sketch_index]
        except:
            return None

    clipAdded = Signal(int, int, QObject)
    clipRemoved = Signal(int, int, QObject)
