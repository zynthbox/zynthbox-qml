#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian PlayGrid: A page to play ntoes with buttons
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
import ctypes as ctypes
import math

from PySide2.QtCore import Property, QObject, Signal

from . import libzl
from .zynthiloops_clip import zynthiloops_clip
from .zynthiloops_song import zynthiloops_song
from .. import zynthian_qt_gui_base


@ctypes.CFUNCTYPE(None)
def cb():
    zynthian_gui_zynthiloops.__instance__.metronome_update()


class zynthian_gui_zynthiloops(zynthian_qt_gui_base.ZynGui):
    __instance__ = None

    def __init__(self, parent=None):
        super(zynthian_gui_zynthiloops, self).__init__(parent)
        zynthian_gui_zynthiloops.__instance__ = self
        self.__current_beat__ = 0
        self.__metronome_running_refcount = 0
        self.__song__ = zynthiloops_song(self)
        self.__song__.bpm_changed.connect(self.update_timer_bpm)
        self.__clips_queue__: list[zynthiloops_clip] = []
        libzl.registerTimerCallback(cb)
        libzl.registerGraphicTypes()

    def show(self):
        pass

    @Signal
    def current_beat_changed(self):
        pass

    @Signal
    def metronome_running_changed(self):
        pass

    @Property(QObject, constant=True)
    def song(self):
        return self.__song__

    def update_timer_bpm(self):
        if self.__metronome_running_refcount > 0:
            libzl.startTimer(math.floor((60.0 / self.__song__.__bpm__) * 1000))

    def start_metronome_request(self, clip: zynthiloops_clip):
        self.__metronome_running_refcount += 1

        self.__clips_queue__.append(clip)

        if self.__metronome_running_refcount == 1:
            libzl.startTimer(math.floor((60.0 / self.__song__.__bpm__) * 1000))
            self.metronome_running_changed.emit()

    def stop_metronome_request(self, clip: zynthiloops_clip):
        self.__metronome_running_refcount = max(self.__metronome_running_refcount - 1, 0)

        try:
            self.__clips_queue__.remove(clip)
        except Exception as e:
            logging.error(f"Error removing clip from playing queue : {str(e)}")

        if self.__metronome_running_refcount == 0:
            libzl.stopTimer()
            self.metronome_running_changed.emit()

            self.__current_beat__ = 0
            self.current_beat_changed.emit()


    def metronome_update(self):
        self.__current_beat__ = (self.__current_beat__ + 1) % 4

        if self.__current_beat__ == 1:
            for q_clip in self.__clips_queue__:
                q_clip.playAudio(False)

        if self.__current_beat__ == 4:
            for q_clip in self.__clips_queue__:
                q_clip.stopAudio()

        self.current_beat_changed.emit()
        if self.__song__.isPlaying:
            self.__song__.metronome_update()

    @Property(int, notify=current_beat_changed)
    def currentBeat(self):
        return self.__current_beat__

    @Property(bool, notify=metronome_running_changed)
    def isMetronomeRunning(self):
        return self.__metronome_running_refcount > 0


