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
from .zynthiloops_track import zynthiloops_track
from .zynthiloops_part import zynthiloops_part
from .zynthiloops_parts_model import zynthiloops_parts_model
from .zynthiloops_tracks_model import zynthiloops_tracks_model


class zynthiloops_song(QObject):
    __track_counter__ = 0
    __bpm__ = 120
    __index__ = 0

    def __init__(self, parent=None):
        super(zynthiloops_song, self).__init__(parent)

        self.__tracks_model__ = zynthiloops_tracks_model(self)
        self.__parts_model__ = zynthiloops_parts_model(self)

    @Property(bool, constant=True)
    def playable(self):
        return False

    @Property(bool, constant=True)
    def recordable(self):
        return False

    @Property(bool, constant=True)
    def clearable(self):
        return False

    @Property(bool, constant=True)
    def deletable(self):
        return False

    @Property(str, constant=True)
    def name(self):
        return f"Song {self.__index__+1}"

    @Signal
    def bpm_changed(self):
        pass

    @Signal
    def index_changed(self):
        pass

    @Signal
    def __tracks_model_changed__(self):
        pass

    @Signal
    def __parts_model_changed__(self):
        pass

    @Property(QObject, notify=__tracks_model_changed__)
    def tracksModel(self):
        return self.__tracks_model__

    @Property(QObject, notify=__parts_model_changed__)
    def partsModel(self):
        return self.__parts_model__

    @Slot(None)
    def addTrack(self):
        self.__track_counter__ += 1
        self.__tracks_model__.add_track(zynthiloops_track(self.__track_counter__, self.__tracks_model__))

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

