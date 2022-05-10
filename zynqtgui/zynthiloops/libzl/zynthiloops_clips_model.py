#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to store parts of a song in ZynthiLoops
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

from .zynthiloops_clip import zynthiloops_clip


class zynthiloops_clips_model(QAbstractListModel):
    ClipIndexRole = Qt.UserRole + 1
    NameRole = ClipIndexRole + 1
    ClipRole = ClipIndexRole + 2
    __clips__: [zynthiloops_clip] = []

    def __init__(self, song, parentTrack=None):
        super().__init__(parentTrack)
        self.__track__ = parentTrack
        self.__song__ = song
        self.__clips__ = []

    def serialize(self):
        data = []
        for c in self.__clips__:
            data.append(c.serialize())
        return data

    def deserialize(self, arr, part_index):
        if not isinstance(arr, list):
            for i in range(2):
                clip = zynthiloops_clip(self.__track__.id, i, part_index, self.__song__, self)
                self.add_clip(clip)
            raise Exception("Invalid json format for clips")

        if len(arr) == 0:
            for i in range(2):
                clip = zynthiloops_clip(self.__track__.id, i, part_index, self.__song__, self)
                self.add_clip(clip)
            return
        for i, c in enumerate(arr):
            clip = zynthiloops_clip(self.__track__.id, i, part_index, self.__song__, self)
            clip.deserialize(c)
            self.add_clip(clip)
            #self.__song__.add_clip_to_part(clip, i)

    def data(self, index, role=None):
        if not index.isValid():
            return None

        if index.row() > len(self.__clips__):
            return None

        if role == self.ClipIndexRole:
            return self.__clips__[index.row()].clipIndex
        elif role == self.NameRole or role == Qt.DisplayRole :
            return self.__clips__[index.row()].name
        elif role == self.ClipRole:
            return self.__clips__[index.row()]
        else:
            return None

    def roleNames(self):
        role_names = {
            Qt.DisplayRole: b'display',
            self.ClipIndexRole: b"clipIndex",
            self.NameRole: b"name",
            self.ClipRole: b"clip"
        }

        return role_names

    def rowCount(self, index):
        return len(self.__clips__)

    def add_clip(self, clip: zynthiloops_clip):
        length = len(self.__clips__)

        self.beginInsertRows(QModelIndex(), length, length)
        self.__clips__.append(clip)
        self.endInsertRows()
        self.countChanged.emit()


    @Slot(int, result=QObject)
    def getClip(self, row : int):
        if row < 0 or row >= len(self.__clips__):
            return None
        return self.__clips__[row]


    @Signal
    def countChanged(self):
        pass


    def count(self):
        return len(self.__clips__)
    count = Property(int, count, notify=countChanged)
