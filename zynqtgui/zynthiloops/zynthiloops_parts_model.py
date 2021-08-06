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
from PySide2.QtCore import QAbstractListModel, QModelIndex, Qt

from zynqtgui.zynthiloops.zynthiloops_part import zynthiloops_part


class zynthiloops_parts_model(QAbstractListModel):
    PartIndexRole = Qt.UserRole + 1
    NameRole = PartIndexRole + 1
    __parts__: [zynthiloops_part] = []

    def __init__(self, parent=None):
        super().__init__(parent)

        for i in range(0, 4):
            self.add_part(zynthiloops_part(i, self))

    def data(self, index, role=None):
        if not index.isValid():
            return None

        if index.row() > len(self.__parts__):
            return None

        if role == self.PartIndexRole:
            return self.__parts__[index.row()].partIndex
        elif role == self.NameRole:
            return self.__parts__[index.row()].name
        else:
            return self.__parts__[index.row()]

    def roleNames(self):
        role_names = {
            self.PartIndexRole: b"partIndex",
            self.NameRole: b"name",
        }

        return role_names

    def rowCount(self, index):
        return len(self.__parts__)

    def add_part(self, part: zynthiloops_part):
        length = len(self.__parts__)

        self.beginInsertRows(QModelIndex(), length, length)
        self.__parts__.append(part)
        self.endInsertRows()
