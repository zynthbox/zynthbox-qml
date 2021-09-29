#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to for storing session sketches
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
from pathlib import Path

from PySide2.QtCore import QAbstractListModel, QModelIndex, QObject, Qt, Property, Signal, Slot

from zynqtgui.zynthiloops.libzl.zynthiloops_song import zynthiloops_song


class session_dashboard_session_sketches_model(QAbstractListModel):
    Sketch = Qt.UserRole + 1

    def __init__(self, parent=None):
        super(session_dashboard_session_sketches_model, self).__init__(parent)
        self.__sketches__ = {}

    ### Property count
    def count(self):
        return len(self.__sketches__)

    countChanged = Signal()
    count = Property(int, count, notify=countChanged)
    ### END Property count

    @Slot(int, result=QObject)
    def getSketch(self, id: int):
        if id < 0 or id >= len(self.__sketches__):
            return None
        return self.__sketches__[id]

    def data(self, index, role=None):
        if not index.isValid():
            return None

        if index.row() >= len(self.__sketches__):
            return None

        if role == self.SketchRole:
            return self.__sketches__[index.row()]
        else:
            return None

    def roleNames(self):
        role_names = {
            self.SketchRole: b"sketch",
        }

        return role_names

    def rowCount(self, index):
        return len(self.__sketches__)

    def add_sketch(self, id, sketch):
        self.beginInsertRows(QModelIndex(), id, id)
        self.__sketches__[id] = sketch
        self.endInsertRows()
        self.countChanged.emit()

    def serialize(self):
        res = {}
        for key, sketch in self.__sketches__.items():
            if sketch is not None:
                res[key] = sketch.sketch_folder+sketch.name+".json"

        return res

    def deserialize(self, obj):
        for i in range(1, 12):
            if i in obj and obj[i] is not None:
                sketch_path = Path(obj[i])
                self.add_sketch(i, zynthiloops_song(str(sketch_path.parent.absolute()) + "/", str(sketch_path.stem), self))
            else:
                self.add_sketch(i, None)
