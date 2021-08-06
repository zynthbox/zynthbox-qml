#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthiloops Part: An object to store clips of a part
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


class zynthiloops_part(QObject):
    __length__ = 1
    __clips__ = []
    __part_index__ = 0
    __is_playing__ = False

    def __init__(self, part_index: int, parent=None):
        super(zynthiloops_part, self).__init__(parent)
        self.__part_index__ = part_index

    @Property(bool, constant=True)
    def playable(self):
        return True

    @Property(bool, constant=True)
    def recordable(self):
        return False

    @Property(bool, constant=True)
    def clearable(self):
        return True

    @Property(bool, constant=True)
    def deletable(self):
        return True

    @Signal
    def __is_playing_changed__(self):
        pass

    @Property(bool, notify=__is_playing_changed__)
    def isPlaying(self):
        return self.__is_playing__

    @isPlaying.setter
    def __set_is_playing__(self, is_playing: bool):
        self.__is_playing__ = is_playing
        self.__is_playing_changed__.emit()

    @Signal
    def length_changed(self):
        pass

    @Signal
    def part_index_changed(self):
        pass

    @Property(int, notify=length_changed)
    def length(self):
        return self.__length__

    @length.setter
    def set_length(self, length: int):
        self.__length__ = length
        self.length_changed.emit()

    @Property(int, notify=part_index_changed)
    def partIndex(self):
        return self.__part_index__

    @partIndex.setter
    def set_part_index(self, part_index):
        self.__part_index__ = part_index
        self.part_index_changed.emit()

    @Property(str, constant=True)
    def name(self):
        return f"Part {self.__part_index__+1}"

    @Slot(QObject, int)
    def addClip(self, clip: QObject, index: int):
        self.__clips__.insert(index, clip)
