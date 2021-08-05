#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthiloops Song: An object to store song information
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


class zynthiloops_song(QObject):
    __bpm__ = 120
    __index__ = 0

    @Signal
    def bpm_changed(self):
        pass

    @Signal
    def index_changed(self):
        pass

    @Property(int, notify=bpm_changed)
    def bpm(self):
        return self.__bpm__

    @bpm.setter
    def set_bpm(self, bpm: int):
        self.__bpm__ = bpm
        self.bpm_changed.emit()

    @Property(int, notify=index_changed)
    def index(self):
        return self.__index__

    @index.setter
    def set_index(self, index):
        self.__index__ = index
        self.index_changed.emit()

