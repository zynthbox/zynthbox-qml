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


class song_arranger_tracks_model(QAbstractListModel):
    TrackRole = Qt.UserRole + 1
    ZLTrackRole = TrackRole + 1

    def __init__(self, parent=None):
        super(song_arranger_tracks_model, self).__init__(parent)
        self.__tracks__ = []

    ### Property count
    def count(self):
        return len(self.__tracks__)

    countChanged = Signal()
    count = Property(int, count, notify=countChanged)
    ### END Property count

    @Slot(int, result=QObject)
    def getTrack(self, row: int):
        if row < 0 or row >= len(self.__tracks__):
            return None
        return self.__tracks__[row]

    def data(self, index, role=None):
        logging.info(index.row(), self.__tracks__[index.row()])

        if not index.isValid():
            return None

        if index.row() >= len(self.__tracks__):
            return None

        if role == self.TrackRole:
            return self.__tracks__[index.row()]
        elif role == self.ZLTrackRole:
            return self.__tracks__[index.row()].zlTrack
        else:
            return None

    def roleNames(self):
        role_names = {
            self.TrackRole: b"track",
            self.ZLTrackRole: b"zlTrack",
        }

        return role_names

    def rowCount(self, index):
        return len(self.__tracks__)

    def add_track(self, track):
        length = len(self.__tracks__)

        self.beginInsertRows(QModelIndex(), length, length)
        self.__tracks__.append(track)
        self.endInsertRows()
        self.countChanged.emit()

    def clear(self):
        if len(self.__tracks__) > 0:
            self.beginRemoveRows(QModelIndex(), 0, len(self.__tracks__)-1)

            for track in self.__tracks__:
                for cell_index in range(0, track.cellsModel.count):
                    cell = track.cellsModel.getCell(cell_index)
                    cell.destroy()

            self.__tracks__ = []
            self.endRemoveRows()
