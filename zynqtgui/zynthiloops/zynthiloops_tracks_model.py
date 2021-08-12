#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to for storing tracks in ZynthiLoops page
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

from PySide2.QtCore import QAbstractListModel, QModelIndex, QObject, Qt, Property, Signal, Slot
from .zynthiloops_track import zynthiloops_track


class zynthiloops_tracks_model(QAbstractListModel):
    IdRole = Qt.UserRole + 1
    NameRole = Qt.UserRole + 2
    TrackRole = Qt.UserRole + 3

    __tracks__: [zynthiloops_track] = []

    def __init__(self, parent: QObject = None):
        super(zynthiloops_tracks_model, self).__init__(parent)

    def data(self, index, role=None):
        logging.info(index.row(), self.__tracks__[index.row()])

        if not index.isValid():
            return None

        if index.row() >= len(self.__tracks__):
            return None

        if role == self.IdRole:
            return self.__tracks__[index.row()].id
        elif role == self.NameRole or role == Qt.DisplayRole:
            return self.__tracks__[index.row()].name
        elif role == self.TrackRole:
            return self.__tracks__[index.row()]
        else:
            return None

    def roleNames(self):
        role_names = {
            Qt.DisplayRole: b'display',
            self.IdRole: b"id",
            self.NameRole: b"name",
            self.TrackRole: b"track"
        }

        return role_names

    def rowCount(self, index):
        return len(self.__tracks__)

    def add_track(self, track: zynthiloops_track):
        length = len(self.__tracks__)

        self.beginInsertRows(QModelIndex(), length, length)
        self.__tracks__.append(track)
        self.endInsertRows()
        self.countChanged.emit()

    @Slot(int, result=QObject)
    def getTrack(self, row : int):
        if row < 0 or row >= len(self.__tracks__):
            return None
        return self.__tracks__[row]


    @Signal
    def countChanged(self):
        pass

    @Property(int, notify=countChanged)
    def count(self):
        return len(self.__tracks__)


