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
import logging
from pathlib import Path

from PySide2.QtCore import QAbstractListModel, QModelIndex, QObject, Qt, Property, Signal, Slot

from zynqtgui.zynthiloops.libzl.zynthiloops_song import zynthiloops_song


class session_dashboard_session_sketches_model(QAbstractListModel):
    SketchRole = Qt.UserRole + 1
    SlotRole = SketchRole + 1

    def __init__(self, parent=None):
        super(session_dashboard_session_sketches_model, self).__init__(parent)
        self.__sketches__ = {}
        self.__session_dashboard__ = parent

        self.clear()

    ### Property count
    def count(self):
        return len(self.__sketches__)

    countChanged = Signal()
    count = Property(int, count, notify=countChanged)
    ### END Property count

    @Slot(int, result=QObject)
    def getSketch(self, slot: int):
        if slot not in self.__sketches__:
            return None
        return self.__sketches__[slot]

    def data(self, index, role=None):
        if not index.isValid():
            return None

        if index.row() not in self.__sketches__:
            return None

        if role == self.SketchRole:
            return self.__sketches__[index.row()]
        elif role == self.SlotRole:
            return index.row()
        else:
            return None

    def roleNames(self):
        role_names = {
            self.SketchRole: b"sketch",
            self.SlotRole: b"slot",
        }

        return role_names

    def rowCount(self, index):
        return len(self.__sketches__)

    def add_sketch(self, slot, sketch):
        self.beginRemoveRows(QModelIndex(), slot, slot)
        self.endRemoveRows()

        self.beginInsertRows(QModelIndex(), slot, slot)

        if sketch is None:
            self.__sketches__[slot] = sketch
        else:
            sketch_path = Path(sketch)
            self.__sketches__[slot] = zynthiloops_song(str(sketch_path.parent.absolute()) + "/", str(sketch_path.stem), self.__session_dashboard__.zyngui.zynthiloops)
            logging.debug(f"Session add sketch : {slot}, {sketch_path}, {self.__sketches__[slot]}")

        self.endInsertRows()

    def serialize(self):
        res = {}
        for key, sketch in self.__sketches__.items():
            if sketch is not None:
                res[key] = sketch.sketch_folder+sketch.name+".json"

        return res

    def deserialize(self, obj):
        logging.debug(f"Deserializing session sketches : {obj}")
        for i in range(0, 11):
            try:
                logging.debug(f"{i}, {obj[str(i)]}")
            except:
                pass

            if str(i) in obj and obj[str(i)]:
                self.add_sketch(i, obj[str(i)])
            else:
                self.add_sketch(i, None)

    def clear(self):
        if len(self.__sketches__) > 0:
            self.beginRemoveRows(QModelIndex(), 0, len(self.__sketches__)-1)
            self.__sketches__ = {}
            self.endRemoveRows()

        for i in range(0, 11):
            self.add_sketch(i, None)
