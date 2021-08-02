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


from PySide2.QtCore import QAbstractListModel, QModelIndex, QObject, Qt
from .zynthiloops_track import ZynthiLoopsTrack


class ZynthiLoopsTracksModel(QAbstractListModel):
    IdRole = Qt.UserRole + 1
    NameRole = IdRole + 1

    __tracks__: [ZynthiLoopsTrack] = []

    def __init__(self, parent: QObject = None):
        super(ZynthiLoopsTracksModel, self).__init__(parent)

    def data(self, index, role=None):
        if not index.isValid():
            return None

        if index.row() >= len(self.__tracks__):
            return None

        if role == self.IdRole:
            return self.__tracks__[index.row()].id
        elif role == self.NameRole:
            return self.__tracks__[index.row()].name

    def roleNames(self):
        role_names = {
            self.IdRole: b"id",
            self.NameRole: b"name",
        }

        return role_names

    def rowCount(self, index):
        return len(self.__tracks__)

    def add_track(self, track: ZynthiLoopsTrack):
        length = len(self.__tracks__)

        self.beginInsertRows(QModelIndex(), length, length)
        self.__tracks__.append(track)
        self.endInsertRows()
