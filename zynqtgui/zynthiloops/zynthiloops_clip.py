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

from .. import zynthian_gui_config
from . import libzl
from PySide2.QtCore import Property, QObject, QThread, Signal, Slot

from .libzl import libzlClip

import logging

class zynthiloops_clip(QObject):
    __length__ = 1
    __row_index__ = 0
    __col_index__ = 0
    __is_playing__ = False

    def __init__(self, row_index: int, col_index: int, song: QObject, parent=None):
        super(zynthiloops_clip, self).__init__(parent)
        self.zyngui = zynthian_gui_config.zyngui
        self.__length__ = 1
        self.__row_index__ = row_index
        self.__col_index__ = col_index
        self.__is_playing__ = False
        self.__start_position__ = 0.0
        self.__path__ = None
        self.__song__ = song
        self.libzlClip = None

    @Signal
    def length_changed(self):
        pass

    @Signal
    def row_index_changed(self):
        pass

    @Signal
    def col_index_changed(self):
        pass

    @Signal
    def path_changed(self):
        pass

    @Signal
    def start_position_changed(self):
        pass

    @Signal
    def duration_changed(self):
        pass

    @Signal
    def __is_playing_changed__(self):
        pass

    @Property(bool, constant=True)
    def playable(self):
        return True

    @Property(bool, constant=True)
    def recordable(self):
        return True

    @Property(bool, constant=True)
    def clearable(self):
        return True

    @Property(bool, constant=True)
    def deletable(self):
        return False

    @Property(bool, constant=True)
    def nameEditable(self):
        return False

    @Property(bool, notify=__is_playing_changed__)
    def isPlaying(self):
        return self.__is_playing__

    @Property(int, notify=length_changed)
    def length(self):
        return self.__length__

    @length.setter
    def set_length(self, length: int):
        self.__length__ = length
        self.length_changed.emit()

        if self.libzlClip is not None:
            self.libzlClip.set_length(min(self.duration - self.__start_position__, (60.0 / self.__song__.bpm) * self.__length__))


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
        return f"Clip {self.__col_index__ + 1}"

    @Property(float, notify=start_position_changed)
    def startPosition(self):
        return self.__start_position__

    @startPosition.setter
    def set_start_position(self, position: float):
        self.__start_position__ = position
        self.start_position_changed.emit()
        if self.libzlClip is None:
            return
        self.libzlClip.set_start_position(position)

    @Property(float, notify=duration_changed)
    def duration(self):
        if self.libzlClip is None:
            return 0.0
        return self.libzlClip.get_duration()

    @Property(str, notify=path_changed)
    def path(self):
        return self.__path__

    @path.setter
    def set_path(self, path):
        self.__path__ = path
        self.stop()
        self.libzlClip = libzlClip(path.encode('utf-8'))
        self.startPosition = self.__start_position__
        self.length = self.__length__

        # self.libzlClip.setStartPosition(self.__start_position__)
        self.path_changed.emit()
        self.duration_changed.emit()

    @Slot(None)
    def clear(self, loop=True):
        self.stop()
        self.libzlClip = None
        self.__path__ = None
        self.path_changed.emit()

    @Slot(None)
    def play(self, loop=True):
        if self.libzlClip is None:
            return
        logging.error(self.zyngui)
        logging.error(self.zyngui.screens['zynthiloops'])
        self.zyngui.screens['zynthiloops'].start_metronome_request()
        self.__is_playing__ = True
        self.__is_playing_changed__.emit()
        self.libzlClip.play()

    @Slot(None)
    def stop(self, loop=True):
        if self.libzlClip is None:
            return
        self.zyngui.screens['zynthiloops'].stop_metronome_request()
        self.__is_playing__ = False
        self.__is_playing_changed__.emit()
        self.libzlClip.stop()
