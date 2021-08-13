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
import ctypes as ctypes
import math

from PySide2.QtCore import Qt, Property, QObject, Signal, Slot

from . import libzl
from .zynthiloops_track import zynthiloops_track
from .zynthiloops_part import zynthiloops_part
from .zynthiloops_parts_model import zynthiloops_parts_model
from .zynthiloops_tracks_model import zynthiloops_tracks_model

import logging

@ctypes.CFUNCTYPE(None)
def cb():
    zynthiloops_song.__instance__.metronome_update()


class zynthiloops_song(QObject):
    __instance__ = None

    def __init__(self, parent=None):
        super(zynthiloops_song, self).__init__(parent)
        zynthiloops_song.__instance__ = self

        self.__tracks_model__ = zynthiloops_tracks_model(self)
        self.__parts_model__ = zynthiloops_parts_model(self)
        self.__track_counter__ = 0
        self.__bpm__ = 120
        self.__index__ = 0
        self.__is_playing__ = False

        self.__current_bar__ = 0
        self.__current_beat__ = 0
        self.__current_part__ = self.__parts_model__.getPart(0)

        libzl.registerTimerCallback(cb)
        #libzl.startTimer(math.floor((60.0 / self.__bpm__) * 1000))

    @Property(bool, constant=True)
    def playable(self):
        return True

    @Property(bool, constant=True)
    def recordable(self):
        return False

    @Property(bool, constant=True)
    def clearable(self):
        return False

    @Property(bool, constant=True)
    def deletable(self):
        return False

    @Property(bool, constant=True)
    def nameEditable(self):
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
    def __is_playing_changed__(self):
        pass

    @Signal
    def current_beat_changed(self):
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

    @Property(bool, notify=__is_playing_changed__)
    def isPlaying(self):
        return self.__is_playing__

    @Slot(None)
    def addTrack(self):
        self.__track_counter__ += 1
        self.__tracks_model__.add_track(zynthiloops_track(self.__track_counter__, self, self.__tracks_model__))

    @Property(int, notify=bpm_changed)
    def bpm(self):
        return self.__bpm__

    @bpm.setter
    def set_bpm(self, bpm: int):
        self.__bpm__ = bpm
        libzl.startTimer(math.floor((60.0 / self.__bpm__) * 1000))
        self.bpm_changed.emit()

    @Property(int, notify=current_beat_changed)
    def currentBeat(self):
        return self.__current_beat__


    @Property(int, notify=index_changed)
    def index(self):
        return self.__index__

    @index.setter
    def set_index(self, index):
        self.__index__ = index
        self.index_changed.emit()

    def metronome_update(self):
        logging.error("metronome tick")
        if self.__current_part__.length == self.__current_bar__:
            for i in range(0, self.__tracks_model__.count):
                track = self.__tracks_model__.getTrack(i)
                clip = track.clipsModel.getClip(self.__current_part__.partIndex)
                clip.stop()

            if self.__current_part__.partIndex == self.__parts_model__.count - 1:
                self.__current_part__ = self.__parts_model__.getPart(0)
            else:
                self.__current_part__ = self.__parts_model__.getPart(self.__current_part__.partIndex + 1)

            self.__current_bar__ = 0

            for i in range(0, self.__tracks_model__.count):
                track = self.__tracks_model__.getTrack(i)
                clip = track.clipsModel.getClip(self.__current_part__.partIndex)
                clip.play()

        self.__current_beat__ = (self.__current_beat__ + 1) % 4
        if self.__current_beat__ is 0:
            self.__current_bar__ = self.__current_bar__ + 1
        self.current_beat_changed.emit()
        logging.error("current beat: {} bar: {}".format(self.__current_beat__, self.__current_bar__))

    @Slot(None)
    def play(self):
        self.__current_bar__ = 0
        self.__current_part__ = self.__parts_model__.getPart(0)
        self.__is_playing__ = True
        libzl.startTimer(math.floor((60.0 / self.__bpm__) * 1000))
        self.__is_playing_changed__.emit()

        for i in range(0, self.__tracks_model__.count):
            track = self.__tracks_model__.getTrack(i)
            clip = track.clipsModel.getClip(self.__current_part__.partIndex)
            clip.play()

    @Slot(None)
    def stop(self):
        self.__current_bar__ = 0
        self.__is_playing__ = False
        #self.__metronome_timer__.stop()
        libzl.stopTimer()
        for i in range(0, self.__tracks_model__.count):
            track = self.__tracks_model__.getTrack(i)
            clip = track.clipsModel.getClip(self.__current_part__.partIndex)
            clip.stop()
        self.__is_playing_changed__.emit()
