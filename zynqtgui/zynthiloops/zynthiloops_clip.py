#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthiloops Clip: An object to store clip information for a track
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
from PySide2.QtCore import Property, QObject, Signal, Slot


class zynthiloops_clip(QObject):
    __length__ = 1
    __row_index__ = 0
    __col_index__ = 0

    @Signal
    def length_changed(self):
        pass

    @Signal
    def row_index_changed(self):
        pass

    @Signal
    def col_index_changed(self):
        pass

    @Property(int, notify=length_changed)
    def length(self):
        return self.__length__

    @length.setter
    def set_length(self, length: int):
        self.__length__ = length
        self.length_changed.emit()

    @Property(int, notify=row_index_changed)
    def row(self):
        return self.__row_index__

    @row.setter
    def set_row_index(self, index):
        self.__row_index__ = index
        self.row_index_changed.emit()

    @Property(int, notify=col_index_changed)
    def col(self):
        return self.__col_index__

    @col.setter
    def set_col_index(self, index):
        self.__col_index__ = index
        self.col_index_changed.emit()

    @Property(str, constant=True)
    def name(self):
        return f"Clip {self.__row_index__ + 1}"
