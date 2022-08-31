#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to store parts of a song in Sketchpad
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
from PySide2.QtCore import QAbstractListModel, QModelIndex, Qt, Property, Signal, Slot, QObject

from .sketchpad_part import sketchpad_part


class sketchpad_parts_model(QAbstractListModel):
    PartIndexRole = Qt.UserRole + 1
    NameRole = PartIndexRole + 1
    PartRole = PartIndexRole + 2

    def __init__(self, parent=None):
        super().__init__(parent)
        self.__song__ = parent
        self.__parts__: [sketchpad_part] = []

    def serialize(self):
        data = []
        for p in self.__parts__:
            data.append(p.serialize())
        return data

    def deserialize(self, arr):
        if not isinstance(arr, list):
            raise Exception("Invalid json format for parts")
        for i, p in enumerate(arr):
            part = sketchpad_part(i, self.__song__, self)
            part.deserialize(p)
            self.add_part(part)

    def data(self, index, role=None):
        if not index.isValid():
            return None

        if index.row() > len(self.__parts__):
            return None

        if role == self.PartIndexRole:
            return self.__parts__[index.row()].partIndex
        elif role == self.NameRole or role == Qt.DisplayRole :
            return self.__parts__[index.row()].name
        elif role == self.PartRole:
            return self.__parts__[index.row()]
        else:
            return None

    def roleNames(self):
        role_names = {
            Qt.DisplayRole: b'display',
            self.PartIndexRole: b"partIndex",
            self.NameRole: b"name",
            self.PartRole: b"part"
        }

        return role_names

    def rowCount(self, index):
        return len(self.__parts__)

    def add_part(self, part: sketchpad_part):
        length = len(self.__parts__)

        self.beginInsertRows(QModelIndex(), length, length)
        self.__parts__.append(part)
        self.endInsertRows()
        self.countChanged.emit()

    @Slot(int, result=QObject)
    def getPart(self, row : int):
        if row < 0 or row >= len(self.__parts__):
            return None
        return self.__parts__[row]

    @Signal
    def countChanged(self):
        pass

    def count(self):
        return len(self.__parts__)
    count = Property(int, count, notify=countChanged)
