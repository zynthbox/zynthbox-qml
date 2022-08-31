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


class song_arranger_cells_model(QAbstractListModel):
    CellIndexRole = Qt.UserRole + 1
    NameRole = CellIndexRole + 1
    CellRole = CellIndexRole + 2

    def __init__(self, parent=None):
        super().__init__(parent)
        self.__channel__ = parent
        self.__cells__ = []

    ### Property count
    def count(self):
        return len(self.__cells__)
    countChanged = Signal()
    count = Property(int, count, notify=countChanged)
    ### END Property count

    @Slot(int, result=QObject)
    def getCell(self, row: int):
        if row < 0 or row >= len(self.__cells__):
            return None
        return self.__cells__[row]

    def data(self, index, role=None):
        if not index.isValid():
            return None

        if index.row() > len(self.__cells__):
            return None

        if role == self.CellIndexRole:
            return self.__cells__[index.row()].cellIndex
        elif role == self.NameRole or role == Qt.DisplayRole:
            return self.__cells__[index.row()].name
        elif role == self.CellRole:
            return self.__cells__[index.row()]
        else:
            return None

    def roleNames(self):
        role_names = {
            Qt.DisplayRole: b'display',
            self.CellIndexRole: b"cellIndex",
            self.NameRole: b"name",
            self.CellRole: b"cell"
        }

        return role_names

    def rowCount(self, index):
        return len(self.__cells__)

    def add_cell(self, cell):
        length = len(self.__cells__)

        self.beginInsertRows(QModelIndex(), length, length)
        self.__cells__.append(cell)
        self.endInsertRows()
        self.countChanged.emit()
