#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to for storing session sketchpads
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

from zynqtgui.sketchpad.sketchpad_song import sketchpad_song


class session_dashboard_session_sketchpads_model(QAbstractListModel):
    SketchpadRole = Qt.UserRole + 1
    SlotRole = SketchpadRole + 1

    def __init__(self, parent=None):
        super(session_dashboard_session_sketchpads_model, self).__init__(parent)
        self.__sketchpads__ = {}
        self.__session_dashboard__ = parent

        self.clear()

    ### Property count
    def count(self):
        return len(self.__sketchpads__)

    countChanged = Signal()
    count = Property(int, count, notify=countChanged)
    ### END Property count

    @Slot(int, result=QObject)
    def getSketchpad(self, slot: int):
        if slot not in self.__sketchpads__:
            return None
        return self.__sketchpads__[slot]

    def data(self, index, role=None):
        if not index.isValid():
            return None

        if index.row() not in self.__sketchpads__:
            return None

        if role == self.SketchpadRole:
            return self.__sketchpads__[index.row()]
        elif role == self.SlotRole:
            return index.row()
        else:
            return None

    def roleNames(self):
        role_names = {
            self.SketchpadRole: b"sketchpad",
            self.SlotRole: b"slot",
        }

        return role_names

    def rowCount(self, index):
        return len(self.__sketchpads__)

    def add_sketchpad(self, slot, sketchpad):
        self.beginRemoveRows(QModelIndex(), slot, slot)
        self.endRemoveRows()

        self.beginInsertRows(QModelIndex(), slot, slot)

        if sketchpad is None:
            self.__sketchpads__[slot] = sketchpad
        else:
            sketchpad_path = Path(sketchpad)
            self.__sketchpads__[slot] = sketchpad_song(str(sketchpad_path.parent.absolute()) + "/", str(sketchpad_path.stem), self.__session_dashboard__.zynqtgui.sketchpad)
            logging.debug(f"Session add sketchpad : {slot}, {sketchpad_path}, {self.__sketchpads__[slot]}")

        self.endInsertRows()

    def serialize(self):
        res = {}
        for key, sketchpad in self.__sketchpads__.items():
            if sketchpad is not None:
                res[key] = sketchpad.sketchpad_folder+sketchpad.name+".json"

        return res

    def deserialize(self, obj):
        logging.debug(f"Deserializing session sketchpads : {obj}")
        for i in range(0, 11):
            try:
                logging.debug(f"{i}, {obj[str(i)]}")
            except:
                pass

            if str(i) in obj and obj[str(i)]:
                self.add_sketchpad(i, obj[str(i)])
            else:
                self.add_sketchpad(i, None)

    def clear(self):
        if len(self.__sketchpads__) > 0:
            self.beginRemoveRows(QModelIndex(), 0, len(self.__sketchpads__)-1)
            self.__sketchpads__ = {}
            self.endRemoveRows()

        for i in range(0, 11):
            self.add_sketchpad(i, None)
